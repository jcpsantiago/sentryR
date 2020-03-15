library(magick)
library(bunny)

img_hex_gh <- image_read("man/figures/logo.png") %>%
  image_scale("400x400")

gh_logo <- bunny::github %>%
  image_scale("50x50")

gh <- image_canvas_ghcard("#f7f7f7") %>%
  image_compose(img_hex_gh, gravity = "East", offset = "+100+0") %>%
  image_annotate("Monitor your APIs", gravity = "West", location = "+100-70",
                 color="#242424", size=60, font="Futura", weight = 700) %>%
  image_annotate("R client for sentry.io", gravity = "West", location = "+100-15",
                 color="#6b6b6b", size=36, font="Futura", weight = 300) %>%
  image_compose(gh_logo, gravity="West", offset = "+100+75") %>%
  image_annotate("ozean12/sentryR", gravity="West", location="+160+80",
                 color="#242424", size=50, font="Ubuntu Mono") %>%
  image_border_ghcard("#f7f7f7")

gh
