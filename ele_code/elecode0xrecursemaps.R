# summary

```{r}
#'summarise
summary(AM306.recurse$revisitStats)

#'hist of revisits
hist(AM306.recurse$revisits, breaks = 40, col = "grey", border = NA)

#'hsit fpt
fpt = as.numeric(AM306.recurse$revisitStats$timeInside[AM306.recurse$revisitStats$visitIdx == 1])

hist(fpt, breaks = 100, col = "grey", border = NA, xlim = c(0, 24))

dev.copy(cairo_pdf, "fig0xfptdist.pdf")
dev.off()
```

# plot revisits

```{r plot}

#cairo_pdf(filename = "fig0xelerecurse.pdf", width = 5, height = 5, fallback_resolution = 300)
#'plot with buffers
plot(AM306.recurse, ele.utm[[fewest.points]], alpha = 0.7, col = viridis(max(AM306.recurse$revisits)), pch = 16, cex = 0.5, axis = F)

drawCircle(max(ele.utm[[fewest.points]]$xutm) - 500, min(ele.utm[[fewest.points]]$yutm)+500, radius = 500, lwd = 2)

plot(river.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), add = T, lwd = 0.01)
plot(wh.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), lwd = 0.01, add = T)
plot(rivers, max.plot = 1, col = 2, add = T)
plot(wh, max.plot = 1, col = 2, pch = 13, add = T, axis = F)

dev.copy(cairo_pdf, "fig0xelerecurse.pdf")
dev.off()
```

# plot FPT

```{r}
#'plot fpt
plot(AM306.recurse, ele.utm[[fewest.points]], alpha = 0.7, col = alpha(ifelse(fpt>=0 & fpt <=2, 1, "grey"),0.5), cex = 0.7, axis = F)

plot(river.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), add = T, lwd = 0.01)
plot(wh.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), lwd = 0.01, add = T)
plot(rivers, max.plot = 1, col = 2, add = T)
plot(wh, max.plot = 1, col = 2, pch = 13, add = T, axis = F)

drawCircle(max(ele.utm[[fewest.points]]$xutm) - 500, min(ele.utm[[fewest.points]]$yutm)+500, radius = 500, lwd = 2)

dev.copy(cairo_pdf, "fig0xelefpt.pdf")
dev.off()
```

# boxplot fpt

```{r}
boxplot(fpt ~ hour(ele.utm[[fewest.points]]$time), outline = F, col = "grey", xlab = "Hour of day", ylab = "First Passage Time (hrs)")
```

# Utilisation time

```{r}
util = AM306.recurse$revisitStats %>% group_by(coordIdx) %>% summarise(time = sum(timeInside))

hist(util$time, col = "grey", border = NA, breaks = 30)
```

## plot util

```{r}
#'plot from revisit stats
plot(AM306.recurse, ele.utm[[fewest.points]], alpha = 0.7, col = viridis(max(util$time))[util$time], cex = 0.7, axis = F, pch = 16)

plot(river.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), add = T, lwd = 0.01)
plot(wh.buffer, max.plot = 1, col = heat.colors(1, alpha = 0.3), lwd = 0.01, add = T)
plot(rivers, max.plot = 1, col = 2, add = T)
plot(wh, max.plot = 1, col = 2, pch = 13, add = T, axis = F)

drawCircle(max(ele.utm[[fewest.points]]$xutm) - 500, min(ele.utm[[fewest.points]]$yutm)+500, radius = 500, lwd = 2)

dev.copy(cairo_pdf, "fig0xelefpt.pdf")
dev.off()
```

# Relation to distw

```{r}
#'get distw raster
water = raster::raster("waterraster.tif")
trees = raster::raster("trees_interpolate.tif")
am306 = ele.utm[[fewest.points]]

am306$mindw = raster::extract(water, am306[,c("xutm","yutm")])
am306$trees = raster::extract(trees, am306[,c("xutm","yutm")])
```

## plot against water and trees raster

```{r}
#'plotwater
plot(raster::crop(trees, raster::extent(ele.move[ele.move@trackId == "AM306"])), col = colorRampPalette(rev(brewer.pal(9, "Greys")))(120))

points(am306$xutm, am306$yutm, col = viridis(max(AM306.recurse$revisits))[AM306.recurse$revisits], cex = 0.1)

plot(river.buffer, max.plot = 1, col = topo.colors(10, alpha = 0.3)[3], add = T, lwd = 0.01)
plot(wh.buffer, max.plot = 1, col = topo.colors(10, alpha = 0.3)[3], lwd = 0.01, add = T)
plot(rivers, max.plot = 1, col = 4, add = T)
plot(wh, max.plot = 1, col = 4, pch = 13, add = T, axis = F)

drawCircle(max(ele.utm[[fewest.points]]$xutm) - 500, min(ele.utm[[fewest.points]]$yutm)+500, radius = 500, lwd = 2)

```

```{r}

data = 
  data.frame(cbind(mindw = am306$mindw, fpt, trees = am306$trees)) %>% group_by(dw = round_any(mindw/1e3, 0.5)) %>% summarise(fpt.mean = mean(fpt, na.rm = T), fpt.sd = sd(fpt, na.rm = T), fpt.n = length(fpt)) %>% mutate(ci = qnorm(0.975)*fpt.sd/sqrt(fpt.n))

data2 = 
  data.frame(cbind(mindw = am306$mindw, util = util$time, trees = am306$trees)) %>% group_by(dw = round_any(mindw/1e3, 0.5)) %>% summarise(util.mean = mean(util, na.rm = T), util.sd = sd(util, na.rm = T), util.n = length(util)) %>% mutate(ci = qnorm(0.975)*util.sd/sqrt(util.n))

#'fpt
ggplot()+
  geom_pointrange(data = data, aes(x = dw, y = fpt.mean, ymin = fpt.mean -ci, ymax = fpt.mean+ci))+
  #geom_smooth(aes(x = am306$mindw/1e3, y = fpt))+
  ylim(NA, 10)+xlim(NA, 5)

#'util
ggplot()+
  geom_pointrange(data = data2, aes(x = dw, y = util.mean, ymin = util.mean -ci, ymax = util.mean+ci))#+
#geom_smooth(aes(x = am306$mindw/1e3, y = fpt))+
#ylim(NA, 10)+xlim(NA, 5)
```



