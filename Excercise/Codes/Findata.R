# We start with an example of the World Bank's data on the global financial inclusion  
# You can find the dataset and report here: 
# https://drive.google.com/drive/u/1/folders/1kM4b5t-rFswg9KG2skogvdH54cpMOcC4

library(tidyverse)
library(tidyr)
library(haven)
library(sjlabelled)
library(reshape2)
library(foreign)
library(dplyr)

# Import the data from the Stata, SPSS, and SAS file with `haven` package 
findata <- read_dta(file = "Data/micro_world.dta")

# Print the first ten rows of the dataset 
findata

# Print the last six rows of the dataset 
tail(findata)

# Print rows 11115, 22119, 91115, and 151115 
findata[c(11115,22119,91115,151115),]

# Print number of rows in the column `fin2` and `fin5`
length(findata$fin2)
length(findata$fin5)

# Print number of rows and columns
dim(findata)

# Show the names of the variable
names(findata)
labels(findata)

# filter() allows you to subset observations based on their values.
(fCambodia <- filter(findata, economy == "Cambodia"))

# Show label 
get_label(findata)


# Now, we select some variables, genaral info: fin2 (Yes == 1, NO == 1, DK == 3,
# Refused == 4), unbanked:fin11a-fin11h, saving: fin15, borrowing: fin21 
# (both saving and borrowing used for start, operate or grow a business or farm)
# and the main source of money that they come up: fin25. 
fdata <- findata %>% 
  select(economy, regionwb:fin2, fin11a:fin11h, fin15, fin21, fin25)

fdata

# Rename variables 
fdata <- fdata %>%
  rename("country" = "economy", "region" = "regionwb", "pop" = "pop_adult", 
         "random" = "wpid_random", "gender" = "female", "inc" = "inc_q",
         "emp" = "emp_in", "account" = "fin2", "saving" = "fin15", 
         "borrowed" = "fin21", "finsources" = "fin25")


names(fdata)

# Print data structure 
str(fdata)

# Change data structure and its value

# Gender
fdata$gender
fdata$gender = as.character(fdata$gender)
fdata$gender[fdata$gender == 2]<- "Female" 
fdata$gender[fdata$gender == 1]<- "Male"
fdata$gender<-factor(fdata$gender) # this removes unused levels
levels(fdata$gender)<-c("Female", "Male") # Clean up the messy names of the levels
fdata$gender<- as.numeric(fdata$gender) # convert the categories to a numerical scale (cheating a bit!)
class(fdata$gender)
summary(fdata$gender)

# Education levels
summary(fdata$educ) # Get a simple summary
#fdata$educ = as.integer(fdata$educ)
fdata$educ[fdata$educ == "4"]<- NA # Let's consider all the "4" as missing (NA)
fdata$educ[fdata$educ == "5"]<- NA # Let's consider all the "5" as missing (NA)
fdata$educ<-factor(fdata$educ) # this removes unused levels
levels(fdata$educ)<-c("Completed primary or less", "secondary", 
                      "completed tertiary or more") # Clean up the messy names of the levels
fdata$educ<- as.numeric(fdata$educ) # convert the categories to a numerical scale (cheating a bit!)
summary(fdata$educ)

# Income levels
class(fdata$inc)
summary(fdata$inc) # Get a simple summary
fdata$inc = as.integer(fdata$inc)
fdata$inc <- factor(fdata$inc) # this removes unused levels
levels(fdata$inc) <- c("Poorest", "Second", "Middle", "Fourth", "Richest")
fdata$inc <- as.numeric(fdata$inc)  
summary(fdata$educ)

# Employment 
summary(fdata$emp)
fdata$emp = as.integer(fdata$emp)
fdata$emp <- factor(fdata$emp) # this removes unused levels
levels(fdata$emp) <- c("Out of workforce", "In workforce")
fdata$emp <- as.numeric(fdata$emp)  

# Banks account
summary(fdata$account)
fdata$account = as.integer(fdata$account)
fdata$account[fdata$account == "3"]<- NA
fdata$account[fdata$account == "4"]<- NA 
fdata$account[fdata$account == "2"]<- 0
fdata$account <- factor(fdata$account) 
levels(fdata$account) <- c("No account", "Have account")
fdata$account <- as.numeric(fdata$account)  

# A combination of  fin11a-fin11h to a variable together 
fdata$fin11 <- ifelse(fdata$fin11a == 1 |
                      fdata$fin11b == 1 |
                      fdata$fin11c == 1 |
                      fdata$fin11d == 1 |
                      fdata$fin11e == 1 | 
                      fdata$fin11f == 1 |
                      fdata$fin11g == 1 |
                      fdata$fin11h == 1, 1, 0)

# Remove fin11a-fin11h
fdata <- subset(fdata, 
                select = -c(fin11a:fin11h))

# Saving
fdata$saving = as.integer(fdata$saving)
fdata$saving[fdata$saving == "3"]<- NA
fdata$saving[fdata$saving == "4"]<- NA 
fdata$saving[fdata$saving == "2"]<- 0
fdata$saving <- factor(fdata$saving) 
levels(fdata$saving) <- c("No", "Yes")
fdata$saving <- as.numeric(fdata$saving)  
summary(fdata$saving)

# Borrowed 
fdata$borrowed = as.integer(fdata$borrowed)
fdata$borrowed[fdata$borrowed == "3"]<- NA
fdata$borrowed[fdata$borrowed == "4"]<- NA 
fdata$borrowed[fdata$borrowed == "2"]<- 0
fdata$borrowed <- factor(fdata$borrowed) 
levels(fdata$borrowed) <- c("No", "Yes")
fdata$borrowed <- as.numeric(fdata$borrowed)  
summary(fdata$borrowed)

# Financial Sources 
fdata$finsources = as.integer(fdata$finsources)
fdata$finsources[fdata$finsources == "7"]<- NA
fdata$finsources[fdata$finsources == "8"]<- NA 
fdata$finsources <- factor(fdata$finsources) 
levels(fdata$finsources) <- c("Savings", "Family or friends", "Money from Working",
                              "A bank, employer, or private lender", 
                              "Selling assets", "Some other sources")
fdata$finsources <- as.numeric(fdata$finsources)  
summary(fdata$finsources)
# ------------------------------------------------------------------------------

# To remove all rows with NA values, we use na.omit() function.
final <- na.omit(fdata)



### Aggregate the data at the country-year level

ag <- fdata[c("account", "country", "age")] # make a subset with only the religion variable

attach(ag)
ag <- aggregate(account, by=list(country, age), FUN=mean, na.rm=TRUE)
detach(ag)

molten <- melt(ag,
                   id = c("Group.1", "Group.2"), na.rm=TRUE)

ggplot(molten) +
  geom_line(aes(x=Group.2, y=value, colour=variable)) +
  theme(axis.text.x = element_text(angle = 75, hjust = 1)) +
  facet_wrap(~Group.1)

#-------------------------------------------------------------------------------

ggplot(fdata,
       aes(x = finsources)) + 
  geom_step(aes(y = ..y..), stat = "ecdf") +
  labs(y = "Cumulative Density") + 
  scale_x_discrete(limits = c("1","2","3","4","5", "6"), 
                   breaks = c(1,2,3,4,5, 6),
                   labels=c("Savings", "Family or friends", "Money from Working",
                            "A bank, employer, or private lender", 
                            "Selling assets", "Some other sources"))

ggplot(data = fdata) + 
  geom_bar(mapping = aes(x = finsources))


ggplot(data = fdata) + 
  geom_bar(mapping = aes(x = gender))

ggplot(data = fdata) + 
  geom_bar(mapping = aes(x = account))

ggplot(data = fdata) + 
  geom_bar(mapping = aes(x = emp))



(d<- findata %>% 
  select(economy, fin24:fin25, receive_wages))

filter(d, economy == "Cambodia")


# We can also use filter() for the comparison. R R provides the standard suite: 
# >, >=, <, <=, != (not equal), and == (equal). Please remember that  & is and
# | is or, and ! is not. 
filter(findata, female == 1)
a <- sum(findata$female == 1)

b <- sum(findata$female == 2)
c <- a+b
c


filter(findata, educ == 3 | educ == 1)
# A useful short-hand for this problem is x %in% y.
no <- filter(findata, educ %in% c(1, 3, 5))
no

# Remembering Augustus De Morgan’s law: !(x & y) is the same as !x | !y, 
# and !(x | y) is the same as !x & !y. 

n <- filter(findata, !(age > 60 | educ > 2))
n <- filter(findata, age <= 60, educ <= 2)

# If you want to determine if a value is missing, use is.na():
is.na(findata)

# arrange() works similarly to filter() except that instead of selecting rows, 
# it changes their order.

arrange(findata, fin5, fin9, fin19)

# Use desc() to re-order by a column in descending order:

arrange(findata, desc(educ))

# Select columns with select()
# Select columns by name

select(findata, economy, age, fin2)

# Select all columns between year and day (inclusive)
select(findata, fin3:fin10)

# Select all columns except those from year to day (inclusive)
select(findata, -(fin3:fin10))

# Rename variable 
rename(findata, f1 = fin2)

# Add new variables with mutate()
f1 <- select(findata, 
             economy:age, 
             ends_with("1"), 
             educ, 
)

f1

f2 <- mutate(f1,
       f2 = fin21 - fin27c1,
       f3 = fin27c1/fin39c1 * 6
)

# If you only want to keep the new variables, use transmute():
  
f3 <- transmute(f1,
                 f2 = fin21 - fin27c1,
                 f3 = fin27c1/fin39c1 * 6
)

# Useful creation functions
#Arithmetic operators: +, -, *, /, ^.
#air_time / 60, hours * 60 + minute

# Modular arithmetic: %/% (integer division) and %% (remainder), 
# where x == y * (x %/% y) + (x %% y).
transmute(flights,
          dep_time,
          hour = dep_time %/% 100,
          minute = dep_time %% 100
)

# Logs: log(), log2(), log10()

# Offsets: lead() and lag() allow you to refer to leading or lagging values.

#R provides functions for running sums, products, mins and maxes: cumsum(), 
# cumprod(), cummin(), cummax(); and dplyr provides cummean() for cumulative means. 

#Ranking: there are a number of ranking functions
min_rank(y)

min_rank(desc(y))
# If min_rank() doesn’t do what you need, look at the variants row_number(), 
# dense_rank(), percent_rank(), cume_dist(), ntile(). 

# Grouped summaries with summarise()
summarise(flights, delay = mean(dep_delay, na.rm = TRUE))

by_day <- group_by(flights, year, month, day)
summarise(by_day, delay = mean(dep_delay, na.rm = TRUE))

#Combining multiple operations with the pipe

by_dest <- group_by(flights, dest)
delay <- summarise(by_dest,
                   count = n(),
                   dist = mean(distance, na.rm = TRUE),
                   delay = mean(arr_delay, na.rm = TRUE)
)
#> `summarise()` ungrouping output (override with `.groups` argument)
delay <- filter(delay, count > 20, dest != "HNL")

# It looks like delays increase with distance up to ~750 miles 
# and then decrease. Maybe as flights get longer there's more 
# ability to make up delays in the air?
ggplot(data = delay, mapping = aes(x = dist, y = delay)) +
  geom_point(aes(size = count), alpha = 1/3) +
  geom_smooth(se = FALSE)
#> `geom_smooth()` using method = 'loess' and formula 'y ~ x'

delays <- flights %>% 
  group_by(dest) %>% 
  summarise(
    count = n(),
    dist = mean(distance, na.rm = TRUE),
    delay = mean(arr_delay, na.rm = TRUE)
  ) %>% 
  filter(count > 20, dest != "HNL")
#> `summarise()` ungrouping output (override with `.groups` argument)

flights %>% 
  group_by(year, month, day) %>% 
  summarise(mean = mean(dep_delay, na.rm = TRUE))

# we could also tackle the problem by first removing
not_cancelled <- flights %>% 
  filter(!is.na(dep_delay), !is.na(arr_delay))

not_cancelled %>% 
  group_by(year, month, day) %>% 
  summarise(mean = mean(dep_delay))



# Counts
delays <- not_cancelled %>% 
  group_by(tailnum) %>% 
  summarise(
    delay = mean(arr_delay)
  )
#> `summarise()` ungrouping output (override with `.groups` argument)

ggplot(data = fdata, mapping = aes(x = gender)) + 
  geom_freqpoly(binwidth = 10)


delays <- not_cancelled %>% 
  group_by(tailnum) %>% 
  summarise(
    delay = mean(arr_delay, na.rm = TRUE),
    n = n()
  )
#> `summarise()` ungrouping output (override with `.groups` argument)

ggplot(data = delays, mapping = aes(x = n, y = delay)) + 
  geom_point(alpha = 1/10)

delays %>% 
  filter(n > 25) %>% 
  ggplot(mapping = aes(x = n, y = delay)) + 
  geom_point(alpha = 1/10)


# Convert to a tibble so it prints nicely
batting <- as_tibble(Lahman::Batting)

batters <- batting %>% 
  group_by(playerID) %>% 
  summarise(
    ba = sum(H, na.rm = TRUE) / sum(AB, na.rm = TRUE),
    ab = sum(AB, na.rm = TRUE)
  )
#> `summarise()` ungrouping output (override with `.groups` argument)

batters %>% 
  filter(ab > 100) %>% 
  ggplot(mapping = aes(x = ab, y = ba)) +
  geom_point() + 
  geom_smooth(se = FALSE)
#> `geom_smooth()` using method = 'gam' and formula 'y ~ s(x, bs = "cs")'


#Grouping by multiple variables
daily <- group_by(flights, year, month, day)
(per_day   <- summarise(daily, flights = n()))
(per_month <- summarise(per_day, flights = sum(flights)))
(per_year  <- summarise(per_month, flights = sum(flights)))

# Grouped mutates (and filters)
flights_sml %>% 
  group_by(year, month, day) %>%
  filter(rank(desc(arr_delay)) < 10)

# Standardise to compute per group metrics:
popular_dests %>% 
  filter(arr_delay > 0) %>% 
  mutate(prop_delay = arr_delay / sum(arr_delay)) %>% 
  select(year:day, dest, arr_delay, prop_delay)




ggplot(data = findata) + 
  geom_point(mapping = aes(x = educ, y = economy))

# Let's look at the structure of our dataset
str(findata$educ)

# Level function 
levels(findata$female)

clean <- drop_na(findata$fin10)
summary(findata$educ)
findata$educ[findata$educ=="4"]<-NA