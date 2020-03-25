source("helpers.R")

set.seed(1738)

num_trips = 1000

simulated_trips = tibble(
  miles = runif(num_trips, 1, 10),
  mph = runif(num_trips, 10, 30),
  minutes = miles / mph * 60,
  base_fare = 1.87 + 0.82 * miles + 0.27 * minutes,
  has_surge = runif(num_trips) < 0.2,
  has_discount = runif(num_trips) < 0.2,
  surge_multiplier = 1 + has_surge * runif(num_trips, 0.1, 2),
  discount_dollars = pmin(has_discount * runif(num_trips, 0.1, 0.2) * base_fare * surge_multiplier, 6),
  fare = base_fare * surge_multiplier - discount_dollars
)

ols_model = lm(fare ~ minutes + miles, data = simulated_trips)
robust_model = MASS::rlm(fare ~ minutes + miles, data = simulated_trips, method = "MM", init = "lts")

fake_trip = tibble(miles = 5.5, minutes = 16.5)
predict(ols_model, newdata = fake_trip)
predict(robust_model, newdata = fake_trip)

png("graphs/simulated_trips_ols_vs_robust_regression.png", width = 800, height = 800)
ggplot(simulated_trips, aes(x = miles, y = fare)) +
  geom_point(size = 3, alpha = 0.3) +
  geom_smooth(method = lm, se = FALSE, color = "red", size = 1.5) +
  annotate("text", x = 10.15, y = 23.1, label = "OLS", color = "red", size = 8, hjust = 0, family = font_family) +
  geom_smooth(method = MASS::rlm, se = FALSE, color = "blue", size = 1.5) +
  annotate("text", x = 10.15, y = 19.2, label = "Robust", color = "blue", size = 8, hjust = 0, family = font_family) +
  scale_x_continuous("Miles", breaks = (0:4) * 2.5) +
  scale_y_continuous("Fare", labels = scales::dollar) +
  expand_limits(y = 0, x = c(1, 11)) +
  ggtitle("OLS vs. Robust Regression for 1,000 Simulated Trips") +
  labs(caption = "toddwschneider.com") +
  theme_tws(base_size = 24)
dev.off()
