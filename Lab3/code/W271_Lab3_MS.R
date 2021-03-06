## MIDS W271-4 Lab3           ##
## Carin, Davis, Levato, Song ##


## @knitr Libraries-Functions-Constants
# LIBRARIES, FUNCTIONS AND CONSTANTS -------------------------------------------------
# Load libraries
# library(e1071)
library(gtools)
library(ggplot2)
library(ggfortify)
library(scatterplot3d)
library(scales)
library(knitr)
library(pastecs)
library(car)
# library(sandwich)
# library(lmtest)
library(plyr)
library(dplyr)
library(tidyr)
library(stargazer)
library(pander)
# library(texreg)
# library(weatherData)
library(scales)
library(xts)
library(reshape2)
library(lubridate)
library(forecast)
library(zoo)

library(fGarch)
library(quantmod)
library(tseries)

# Define functions

# A function to apply format
frmt <- function(qty, digits = 3) {
  formatC(qty, digits = digits, format = "f", drop0trailing = FALSE, 
          big.mark = ",")
}

# A function to present descriptive statistics of 1 or more vectors
desc_stat <- function(x, variables, caption) {
  ds <- data.frame(x)
  names(ds) <- letters[1:dim(ds)[2]]
  
  ds <- ds %>%
    gather %>%
    group_by(Variable = key) %>%
    summarise(Mean = mean(value), 'St. Dev' = sd(value), 
              '1st Quartile' = quantile(value, 0.25), Median = median(value),
              '3rd Quartile' = quantile(value, 0.75), Min = min(value), 
              Max = max(value)) %>% 
    select(-Variable) %>% 
    t %>% data.frame
  kable(ds, digits = 2, caption = caption, col.names = variables)
  
  # ds <- ds %>%
  #   summarise_each(funs(Mean =mean, 'St. Dev' = sd, 
  #                       '1st Quartile' = quantile(., 0.25), Median = median, 
  #                       '3rd Quartile' = quantile(., 0.75), Min = min, 
  #                       Max = max)) %>% 
  #   gather
  # if (dim(ds)[1] > 7)
  #   ds <- ds %>%
  #   mutate(Statistic = gsub(".*\\_", "", key),
  #          variable = gsub("\\_.*", "", key)) %>%
  #   select(-key) %>%
  #   spread(key = variable, value = value) %>%
  #   mutate(order = c(3, 5, 7, 1, 3, 6, 2)) %>%
  #   arrange(order) %>%
  #   select(-order)
  # kable(ds, col.names = c('', variables), digits = 2, caption = caption)
}

# Define constants
par(cex.main = 1, cex.lab = 0.9, cex.axis = 0.9)
set.seed(1234)


## @knitr ex2-load
# Loading the Data --------------------------------------------------------
# setwd('./Lab3/data')
#load the data
d<-read.csv('lab3_series02.csv')
str(d)
all(d$X == 1:dim(d)[1]) # check if 1st column is just an incremental index
d <- d[, -1]


## @knitr ex2-desc_stats
# Exploratory Data Analysis -----------------------------------------------
# See the definition of the function in ## @knitr Libraries-Functions-Constants
desc_stat(d, 'Time series', 'Descriptive statistics of the time series.')


## @knitr ex2-hist
hist(d, breaks = 30, col="gray", freq = FALSE, 
     xlab = "Level / Amplitude", main = "Histogram of the time series")
lines(density(d), col = 'blue', lty = 2)
leg.txt <- c("Estimated density plot")
legend("topright", legend = leg.txt, lty = 2, col = "blue", bty = 'n', cex = .8)


## @knitr ex2-time_plot
d.ts <- ts(d)
plot.ts(d.ts, col = 'blue', type = 'l', 
        xlab = "Time period", ylab = "Level / Amplitude", 
        main = "Time-series plot of the data")
abline(h = mean(d), col = 'red', lty = 2)
lines(stats::filter(d.ts, sides=2, rep(1, 7)/7), lty = 1, lwd = 1.5, 
      col = "green")
leg.txt <- c("Time-series", "Mean value", 
             "13-Point Symmetric Moving Average")
legend("topleft", legend = leg.txt, lty = c(1, 2, 1), lwd = c(1, 1, 1.5), 
       col = c("blue", "red", "green"), bty = 'n', cex = .8)

## @knitr ex2-time_plot_zoom
layout(1:1)
plot.ts(window(d.ts, 1332), col = 'blue', type = 'l', 
        xlab = "Time Period", ylab = "Level / Amplitude", 
        main = paste0("Detail of the last 1000 observations"))
plot.ts(window(d.ts, 1967), col = 'blue', type = 'l', 
        xlab = "Time Period", ylab = "Level / Amplitude", 
        main = paste0("Detail of the last 365 observations (year)"))
plot.ts(window(d.ts, 2241), col = 'blue', type = 'l', 
        xlab = "Time Period", ylab = "Level / Amplitude", 
        main = paste0("Detail of the last 91 observations(quarter)"))
plot.ts(window(d.ts, 2272 ), col = 'blue', type = 'l', 
        xlab = "Time Period", ylab = "Level / Amplitude", 
        main = paste0("Detail of the last 60 observations(two months"))


## @knitr ex2-acf_pacf
# ACF and PACF of the Time Series -----------------------------------------
# Plot the ACF and PACF of the series
par(mfrow=c(1, 2))
par(cex.main = 1, cex.lab = 0.9, cex.axis = 0.9)
acf(d.ts, lag.max = 24, main = "ACF of the time series")
pacf(d.ts, lag.max = 24, main = "PACF of the time series")
par(mfrow=c(1, 1))
par(cex.main = 1, cex.lab = 0.9, cex.axis = 0.9)

## @knitr ex2-boxplot
boxplot(d ~ factor(rep(1:22, each = 106)), 
        outcex = 0.4, medcol="red", lwd = 0.5, 
        xlab = 'Year', ylab = 'Level / Amplitude',
        main = 'Box-and-whisker plot of\nthe time series per year')

## @knitr ex2-square_ts
plot.ts(d.ts*d.ts, col = 'purple', type = 'l', 
        xlab = "Time period", ylab = "Level / Amplitude", 
        main = "Squared Time-series plot of the data")

## @knitr ex2-subset
#subset the data to only use observation 1700-2332
d_sub<-d[1500:2332]
d_sub.ts<-ts(d_sub)

## @knitr ex2-sub_time_plot
plot.ts(d_sub.ts, col = 'blue', type = 'l', 
        xlab = "Time period", ylab = "Level / Amplitude", 
        main = "Time-series plot of the data")
abline(h = mean(d_sub), col = 'red', lty = 2)
lines(stats::filter(d_sub.ts, sides=2, rep(1, 7)/7), lty = 1, lwd = 1.5, 
      col = "green")
leg.txt <- c("Time-series", "Mean value", 
             "13-Point Symmetric Moving Average")
legend("topleft", legend = leg.txt, lty = c(1, 2, 1), lwd = c(1, 1, 1.5), 
       col = c("blue", "red", "green"), bty = 'n', cex = .8)

## @knitr ex2-first_diff
d1.ts<-diff(d_sub.ts)
plot(d1.ts)
#Now we take a look at the variance of this differenced model by looking at the squared ts
plot.ts(d1.ts*d1.ts, col = 'purple', type = 'l', 
        xlab = "Time period", ylab = "Level / Amplitude", 
        main = "Squared Time-series plot of the first differenced data")

## @knitr ex2-acf
#conduct the acf of the squared values of the difference to identify conditional heteroskedasticity 
acf((d1.ts-mean(d1.ts))^2, lag.max = 24, main = "ACF of the squared values")


## @knitr ex2-garch
library(tseries)
d1.garch<-garch(d1.ts,  trace=FALSE)
confint(d1.garch)
d1.res <- d1.garch$res[-1]

## @knitr ex2-garch_acf
acf(d1.res)
acf(d1.res^2)


## @knitr P3-load
# Loading the Global Warming Data 
gw<- read.csv('globalWarming.csv', header = TRUE)
head(gw)


## @knitr P3-timeseries
# Create ts object with non-integer frequencies and 
gw_ts <- ts(gw[,2], start = 2004 + 4/265.25, frequency = 365.25/7)
str(gw_ts)


## @knitr P3-timeplot_prod
# Plot ts and its decomposed plots 
plot(gw_ts, xlab = "Time", ylab = " The Interested Level", 
     main = "Interest Levels in Global Warming\nfrom Jan" )

## @knitr P3-plot_seasonal
# Plot its trend and seasonal decomposition
plot(decompose(gw_ts) )

## @knitr P3-acfplot_prod
# Extract a subset of data from 2012 to 2016
# Plot new ts and acf/pacf plots 
gw_ts_new <-window(gw_ts, start = c(2012,1) )
par(mfrow=c(3,2))
plot(gw_ts_new, xlab = "Time",ylab = " The Interested Level", 
     main = paste0(" Interest Levels in Global Warming\nfrom Jan. ", 
                   "2012 to Feb. 2016"))
plot(diff(gw_ts_new),xlab = "Time",ylab= 'Differenced Interest Levels',
     main= 'Differenced Interest Level')
acf(gw_ts_new, main = "ACF of Interest Levels in Global Warming", ylim=c(-0.2,1))
acf(diff(gw_ts_new), main = "ACF of Differenced Interest Levels",ylim=c(-0.2,1))
pacf(diff(gw_ts_new), main = "PACF of Interest Levels",ylim=c(-0.2,1))
pacf(diff(gw_ts_new), main = "PACF of Differenced  Interest Levels",ylim=c(-0.2,1))
invisible(dev.off())

## @knitr P3-best-fit_arima
# Best fit arima model and 12-step ahead forecast
gw_ts_fit <- auto.arima(gw_ts_new)
gw_ts_fit.fcast<-forecast.Arima(gw_ts_fit, h = 12)
gw_ts_fit

## @knitr P3-plot-fit_arima
# Plot best-fit arima model and 12-step ahead forecast
plot(gw_ts_fit.fcast, main="12-Step Ahead Forecast by the Best-fit Model",
     xlab="Time", xlim=c(), lty=2, col="navy")
lines(fitted(gw_ts_fit),col="red" )
leg.txt <- c("Original Series", "Estimated Series")
legend("topleft", legend=leg.txt, lty=c(2,1), 
       col=c("navy","red"), bty='n', cex=1)

## @knitr P3-check-arima_residues
# Plot ACF/PACF for residuals of the best fit ARIMA model to 
# ensure no more information is left for extraction
par(mfrow=c(2,1))
acf(residuals(gw_ts_fit), main='ACF of Residual', ylim=c(-0.2,1))
pacf(residuals(gw_ts_fit),main='PACF of Residual',ylim=c(-0.2,1))
box.test(residuals(gw_ts_fit), type="Ljung" )
invisible(dev.off())

## @knitr P3-best-aic_arima
# Compare the AIC values of manually selected arima models:
# arima(0,1,0), arima(1,1,0), arima(0,1,1), arima(1,1,1), arima(1,1,1)
# arima(0,1,2), arima(1,1,2), arima(2,1,0), arima(2,1,2)
arima010<- arima(gw_ts_new, order=c(0,1,0))
arima110<- arima(gw_ts_new, order=c(1,1,0))
arima011<- arima(gw_ts_new, order=c(0,1,1))
arima111<- arima(gw_ts_new, order=c(1,1,1))
arima012<- arima(gw_ts_new, order=c(0,1,2))
arima112<- arima(gw_ts_new, order=c(1,1,2))
arima210<- arima(gw_ts_new, order=c(2,1,0))
arima212<- arima(gw_ts_new, order=c(2,1,2))
aic_values <- c(arima010$aic, arima110$aic, arima011$aic, arima111$aic, arima012$aic,
                arima012$aic, arima112$aic, arima210$aic, arima212$aic)
aic_values
summary(arima212)

## @knitr P3-check-aic_arima
# Diagonstic Checking for the arima model with the best AIC value:
par(mfrow=c(2,2))
acf(residuals(arima212), main='ACF of Residual from arima212', ylim=c(-0.2,1))
pacf(residuals(arima212),main='PACF of Residual from arima212',ylim=c(-0.2,1))
acf(residuals(arima212)^2, main='ACF of Squared Residual from arima212', ylim=c(-0.2,1))
pacf(residuals(arima212)^2,main='PACF of Squared Residual from arima212',ylim=c(-0.2,1))
invisible(dev.off())

## @knitr P3-forecast-aic_arima
# Forecast using the arima model with the best AIC value
gw_ts_bestaic.fcast<-forecast.Arima(arima212, h = 12)
plot(gw_ts_bestaic.fcast, main="12-Step Ahead Forecast by the Best-AIC Model",
     xlab="Time", xlim=c(), lty=2, col="navy")
lines(fitted(arima212),col="red" )
leg.txt <- c("Original Series", "Estimated Series")
legend("topleft", legend=leg.txt, lty=c(2,1), 
       col=c("navy","red"), bty='n', cex=1)