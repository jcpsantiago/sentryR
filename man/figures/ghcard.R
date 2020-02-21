library(magick)
library(bunny)

img_hex_gh <- image_read("logo.png") %>%
  image_scale("400x400")

gh_logo <- bunny::github %>%
  image_scale("50x50")

gh <- image_canvas_ghcard("#fae9ef") %>%
  image_compose(img_hex_gh, gravity = "East", offset = "+100+0") %>%
  image_annotate("Monitor your APIs", gravity = "West", location = "+100-70",
                 color="#0d4448", size=60, font="Futura", weight = 700) %>%
  image_annotate("R client for sentry.io", gravity = "West", location = "+100-15",
                 color="#0d4448", size=36, font="Futura", weight = 300) %>%
  image_compose(gh_logo, gravity="West", offset = "+100+75") %>%
  image_annotate("ozean12/sentryR", gravity="West", location="+160+80",
                 size=50, font="Ubuntu Mono") %>%
  image_border_ghcard("#fae9ef")

gh
