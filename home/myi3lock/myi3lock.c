/* myi3lock — i3lock-fancy's look, in one executable.
 *
 * Takes a screenshot, darkens and blurs it, draws a lock icon and a prompt in
 * the middle, then execs i3lock-color on the result, with the same colours as
 * i3lock-fancy. It is meant for xss-lock, and therefore runs i3lock-color with
 * `--nofork`. It takes no arguments.
 *
 * NOTE: There is no fork: the image goes to i3lock-color through a memfd, and
 * this process becomes i3lock-color. This matters for xss-lock's
 * `--transfer-sleep-lock`: i3lock-color releases the sleep lock once the
 * screen is locked, and no other process keeps a copy of it, delaying suspend.
 *
 * I3LOCK_COLOR, LOCK_ICON and LOCK_ICON_DARK are set at compile time. */

#define _GNU_SOURCE
#include <cairo-xlib.h>
#include <cairo.h>
#include <math.h>
#include <pango/pangocairo.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define TEXT "Type password to unlock"
#define FONT "Sans 26px"
#define TEXT_OFFSET 160      /* below the centre, as `-annotate +0+160` */
#define SCALE 5              /* blur by downscaling, as `-resize 20%` */
#define BLUR_RADIUS 1        /* plus a little box blur at the small scale */
#define BLUR_PASSES 2
#define GAMMA 0.6            /* darken, as `-level 0%,100%,0.6` */
#define BRIGHTNESS_LIMIT 60  /* in %, above which the background is "light" */

static void die(const char *msg) {
  fprintf(stderr, "myi3lock: %s\n", msg);
  exit(EXIT_FAILURE);
}

/* Brightness (HSB) of the average colour of the central 100x100 square, in %.
 * The surface must be CAIRO_FORMAT_RGB24. */
static double centre_brightness(cairo_surface_t *s) {
  int w = cairo_image_surface_get_width(s), h = cairo_image_surface_get_height(s);
  int stride = cairo_image_surface_get_stride(s);
  unsigned char *data = cairo_image_surface_get_data(s);
  double r = 0, g = 0, b = 0;
  int n = 0;
  for (int y = h / 2 - 50; y < h / 2 + 50; y++) {
    if (y < 0 || y >= h) continue;
    for (int x = w / 2 - 50; x < w / 2 + 50; x++) {
      if (x < 0 || x >= w) continue;
      uint32_t p = *(uint32_t *)(data + y * stride + x * 4);
      r += (p >> 16) & 0xff;
      g += (p >> 8) & 0xff;
      b += p & 0xff;
      n++;
    }
  }
  if (n == 0) return 0;
  return fmax(r, fmax(g, b)) / n / 255 * 100;
}

/* Horizontal then vertical box blur, in place. */
static void box_blur(cairo_surface_t *s, int radius, int passes) {
  int w = cairo_image_surface_get_width(s), h = cairo_image_surface_get_height(s);
  int stride = cairo_image_surface_get_stride(s);
  unsigned char *data = cairo_image_surface_get_data(s);
  int len = w > h ? w : h;
  int *acc = malloc(len * 3 * sizeof(int));
  if (!acc) die("out of memory");
  cairo_surface_flush(s);
  for (int pass = 0; pass < passes; pass++) {
    for (int dir = 0; dir < 2; dir++) {
      int lines = dir ? w : h, count = dir ? h : w;
      for (int l = 0; l < lines; l++) {
        /* pixel i of line l */
#define PX(i) ((uint32_t *)(data + (dir ? (i) * stride + l * 4 : l * stride + (i) * 4)))
        for (int i = 0; i < count; i++) {
          uint32_t p = *PX(i);
          acc[i * 3] = (p >> 16) & 0xff;
          acc[i * 3 + 1] = (p >> 8) & 0xff;
          acc[i * 3 + 2] = p & 0xff;
        }
        for (int i = 0; i < count; i++) {
          int sum[3] = {0, 0, 0}, n = 0;
          for (int k = i - radius; k <= i + radius; k++) {
            if (k < 0 || k >= count) continue;
            for (int c = 0; c < 3; c++) sum[c] += acc[k * 3 + c];
            n++;
          }
          *PX(i) = (sum[0] / n) << 16 | (sum[1] / n) << 8 | (sum[2] / n);
        }
#undef PX
      }
    }
  }
  free(acc);
  cairo_surface_mark_dirty(s);
}

static void darken(cairo_surface_t *s, double gamma) {
  unsigned char table[256];
  for (int i = 0; i < 256; i++)
    table[i] = (unsigned char)(pow(i / 255.0, 1 / gamma) * 255 + 0.5);
  int w = cairo_image_surface_get_width(s), h = cairo_image_surface_get_height(s);
  int stride = cairo_image_surface_get_stride(s);
  unsigned char *data = cairo_image_surface_get_data(s);
  cairo_surface_flush(s);
  for (int y = 0; y < h; y++)
    for (int x = 0; x < w; x++) {
      uint32_t *p = (uint32_t *)(data + y * stride + x * 4);
      *p = table[(*p >> 16) & 0xff] << 16 | table[(*p >> 8) & 0xff] << 8 | table[*p & 0xff];
    }
  cairo_surface_mark_dirty(s);
}

int main(void) {
  /* Screenshot of the root window. */
  Display *display = XOpenDisplay(NULL);
  if (!display) die("cannot open display");
  int screen = DefaultScreen(display);
  int w = DisplayWidth(display, screen), h = DisplayHeight(display, screen);
  cairo_surface_t *root = cairo_xlib_surface_create(
      display, RootWindow(display, screen), DefaultVisual(display, screen), w, h);
  cairo_surface_t *image = cairo_image_surface_create(CAIRO_FORMAT_RGB24, w, h);
  cairo_t *cr = cairo_create(image);
  cairo_set_source_surface(cr, root, 0, 0);
  cairo_paint(cr);
  cairo_destroy(cr);
  cairo_surface_destroy(root);
  XCloseDisplay(display);

  /* Pick the theme from the screenshot, as i3lock-fancy does. */
  int light = centre_brightness(image) > BRIGHTNESS_LIMIT;

  /* Darken, then blur by scaling down, box-blurring and scaling back up. */
  darken(image, GAMMA);
  int sw = w / SCALE > 0 ? w / SCALE : 1, sh = h / SCALE > 0 ? h / SCALE : 1;
  cairo_surface_t *small = cairo_image_surface_create(CAIRO_FORMAT_RGB24, sw, sh);
  cr = cairo_create(small);
  cairo_scale(cr, (double)sw / w, (double)sh / h);
  cairo_set_source_surface(cr, image, 0, 0);
  cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_GOOD);
  cairo_pattern_set_extend(cairo_get_source(cr), CAIRO_EXTEND_PAD);
  cairo_paint(cr);
  cairo_destroy(cr);
  box_blur(small, BLUR_RADIUS, BLUR_PASSES);
  cr = cairo_create(image);
  cairo_save(cr);
  cairo_scale(cr, (double)w / sw, (double)h / sh);
  cairo_set_source_surface(cr, small, 0, 0);
  cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_BILINEAR);
  cairo_pattern_set_extend(cairo_get_source(cr), CAIRO_EXTEND_PAD);
  cairo_paint(cr);
  cairo_restore(cr);
  cairo_surface_destroy(small);

  /* Lock icon in the centre. */
  cairo_surface_t *icon = cairo_image_surface_create_from_png(light ? LOCK_ICON_DARK : LOCK_ICON);
  if (cairo_surface_status(icon) == CAIRO_STATUS_SUCCESS) {
    int iw = cairo_image_surface_get_width(icon), ih = cairo_image_surface_get_height(icon);
    cairo_set_source_surface(cr, icon, (w - iw) / 2.0, (h - ih) / 2.0);
    cairo_paint(cr);
  }
  cairo_surface_destroy(icon);

  /* Prompt below it. */
  PangoLayout *layout = pango_cairo_create_layout(cr);
  PangoFontDescription *font = pango_font_description_from_string(FONT);
  pango_layout_set_font_description(layout, font);
  pango_layout_set_text(layout, TEXT, -1);
  int tw, th;
  pango_layout_get_pixel_size(layout, &tw, &th);
  cairo_move_to(cr, (w - tw) / 2.0, (h - th) / 2.0 + TEXT_OFFSET);
  cairo_set_source_rgb(cr, light ? 0 : 1, light ? 0 : 1, light ? 0 : 1);
  pango_cairo_show_layout(cr, layout);
  pango_font_description_free(font);
  g_object_unref(layout);
  cairo_destroy(cr);
  cairo_surface_flush(image);

  /* Hand the image to i3lock-color through a memfd. RGB24 is stored as
   * native-endian 0x00RRGGBB, that is B, G, R, X in memory on x86. */
  int fd = memfd_create("myi3lock", 0);
  if (fd < 0) die("cannot create memfd");
  int stride = cairo_image_surface_get_stride(image);
  unsigned char *data = cairo_image_surface_get_data(image);
  for (int y = 0; y < h; y++)
    if (write(fd, data + y * stride, w * 4) != w * 4) die("cannot write image");
  cairo_surface_destroy(image);

  char path[32], raw[32];
  snprintf(path, sizeof(path), "/proc/self/fd/%d", fd);
  snprintf(raw, sizeof(raw), "%dx%d:bgrx", w, h);

  const char *params_light[] = {
      "--inside-color=0000001c", "--ring-color=0000003e", "--line-color=00000000",
      "--keyhl-color=ffffff80", "--ringver-color=ffffff00", "--separator-color=22222260",
      "--insidever-color=ffffff1c", "--ringwrong-color=ffffff55", "--insidewrong-color=ffffff1c",
      "--verif-color=ffffff00", "--wrong-color=ff000000", "--time-color=ffffff00",
      "--date-color=ffffff00", "--layout-color=ffffff00"};
  const char *params_dark[] = {
      "--inside-color=ffffff1c", "--ring-color=ffffff3e", "--line-color=ffffff00",
      "--keyhl-color=00000080", "--ringver-color=00000000", "--separator-color=22222260",
      "--insidever-color=0000001c", "--ringwrong-color=00000055", "--insidewrong-color=0000001c",
      "--verif-color=00000000", "--wrong-color=ff000000", "--time-color=00000000",
      "--date-color=00000000", "--layout-color=00000000"};
  const char **params = light ? params_light : params_dark;
  int nparams = sizeof(params_light) / sizeof(*params_light);

  char *args[7 + sizeof(params_light) / sizeof(*params_light)];
  int n = 0;
  args[n++] = "i3lock";
  args[n++] = "--nofork";
  args[n++] = "--image";
  args[n++] = path;
  args[n++] = "--raw";
  args[n++] = raw;
  for (int i = 0; i < nparams; i++) args[n++] = (char *)params[i];
  args[n] = NULL;
  execv(I3LOCK_COLOR, args);
  die("cannot exec i3lock-color");
}
