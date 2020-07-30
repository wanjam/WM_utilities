mygeom <- function (mapping = NULL, data = NULL, stat = "identity",
          position = "identity", show.legend = NA, na.rm = TRUE,
          inherit.aes = TRUE, interpolate = FALSE, interp_limit = "skirt",
          chan_markers = "point", chan_size = rel(2), head_size = rel(1.5),
          grid_res = 200, method = "biharmonic", ...)
{
  list(ggplot2::layer(geom = GeomRaster, stat = StatScalpmap,
                      data = data, mapping = mapping, position = position,
                      show.legend = show.legend, inherit.aes = inherit.aes,
                      params = list(na.rm = na.rm, interpolate = interpolate,
                                    grid_res = grid_res, interp_limit = interp_limit,
                                    method = method, ...)), ggplot2::layer(geom = GeomHead,
                                                                           data = data, mapping = mapping, stat = StatHead, position = PositionIdentity,
                                                                           inherit.aes = inherit.aes, params = list(na.rm = na.rm,
                                                                                                                    size = head_size, interp_limit = interp_limit, ...)),
       ggplot2::layer(data = data, mapping = mapping, stat = StatREar,
                      geom = GeomEars, position = PositionIdentity, show.legend = show.legend,
                      inherit.aes = TRUE, params = list(na.rm = na.rm,
                                                        curvature = -0.5, angle = 60, size = head_size,
                                                        interp_limit = interp_limit, ...)), ggplot2::layer(data = data,
                                                                                                           mapping = mapping, stat = StatLEar, geom = GeomEars,
                                                                                                           position = PositionIdentity, show.legend = show.legend,
                                                                                                           inherit.aes = TRUE, params = list(na.rm = na.rm,
                                                                                                                                             curvature = 0.5, angle = 120, size = head_size,
                                                                                                                                             interp_limit = interp_limit, ...)), if (identical(chan_markers,
                                                                                                                                                                                               "point")) {
                                                                                                                                               ggplot2::layer(data = data, mapping = mapping, stat = StatChannels,
                                                                                                                                                              geom = GeomPoint, position = PositionIdentity,
                                                                                                                                                              show.legend = show.legend, inherit.aes = inherit.aes,
                                                                                                                                                              params = list(na.rm = na.rm, fill = NA, size = chan_size,
                                                                                                                                                                            ...))
                                                                                                                                             } else if (chan_markers == "text") {
                                                                                                                                               ggplot2::layer(data = data, mapping = mapping, stat = StatChannels,
                                                                                                                                                              geom = GeomText, position = PositionIdentity,
                                                                                                                                                              show.legend = show.legend, inherit.aes = inherit.aes,
                                                                                                                                                              params = list(na.rm = na.rm, size = chan_size,
                                                                                                                                                                            ...))
                                                                                                                                             })
}
