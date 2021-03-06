---
title: "Food Safety in Africa"
subtitle: Data Cleaning, Visualization, and Statistical Analysis with R
author: "Yunting Chiu"
date: "4/29/2020"
output:
  pdf_document:
    toc: true
    toc_depth: 2
    fig_caption: true
urlcolor: blue
---
```{r setup, include = FALSE, fig.align = "center"}
knitr::opts_chunk$set(message = FALSE, warning = FALSE, echo = FALSE, collapse = FALSE)
```
## 1 - Team Members
* [**Yunting Chiu**](https://www.linkedin.com/in/yuntingchiu): tidy data, statistical analysis, project management, data mapping, data visualization.
* **Kingsley Ofoegbu**: data analysis, data-driven hypotheses, data visualization, report writing, tidy data, regression.
* **Shan Lin**: report writing, literature review, data evaluation.
* **Doudou Shi**: report writing, data visualization, data analysis, statistical analysis.
   
## 2 - Introduction
Food insecurity is still a major global concern as 1 billion people are suffering from starvation and malnutrition, and the Food and Agriculture Organization of the United Nations (FAO) has concluded that we are still far from reaching millennium development goal (MDG) Number 1: to halve extreme poverty and hunger. Especially in sub-Saharan Africa, where the number of people suffering from hunger is estimated at over 200 million, and this figure could increase in the near future. In this project, we hope to answer certain questions with the data set we have and proffer possible solutions to bring about better Food security in Africa. We know Africa has rich resources when it comes to agriculture and rich soil, but they lack the proper equipment to harvest them is lacking. After this, we should be able to comfortably suggest measures to counter the gaping holes in infrastructure, food supply, hazard control, and questions that need answering.\

The analysis is based on Global Food Safety Partnerships (GFSP) dataset from 49 countries between 2006 to 2017. We are interested in quantitative measurement for this project, especially we compared Africa's GDP and total population.\

## 3 - Data Cleaning
### 3.1 - Loading Libraries
```{r LoadPackages, include = FALSE}
library(tidyverse)
library(dplyr)
library(readxl)
library(readr)
library(ggplot2)
library(spData)
library(ggthemes)
library(sf)
library(knitr)
library(rnaturalearth)
library(rnaturalearthdata)
library(rgeos)
library(ggspatial)
library(lwgeom)
```

### 3.2 - Load the data first, and reformating features
```{r, warning=FALSE}
fsa <- read_csv(file = "./data/gfspafricamapping_final_20192.csv", 
                               col_types = cols("Category" = col_factor(),
                                                "A3_DonorCat" = col_factor(),
                                                "A8_ImplCat" = col_factor(),
                                                "A11_Yearinit" = col_number(),
                                                "A12_YearEnd" = col_number(),
                                                "B1_Project focus" = col_factor(),
                                                "B2_Purpose_p" = col_factor(),
                                                "E2_FSBudget" = col_number(),
                                                "E3_BudgetCat" = col_factor(),
                                                "ID number" = col_character()
                                                ), na = ".")
```

### 3.3 - Reshaping with multiple columns
```{r}
fsa %>% 
  pivot_longer(cols = starts_with("A9_"),names_to = "Country",names_prefix = "A9_",
               values_to = "project_role", values_ptypes = list(logical())) %>% 
  filter(project_role !=0)-> 
  teempA
  teempA %>% 
  pivot_longer(cols = starts_with("B4_"),names_to = "Activity",names_prefix = "B4_Activity_",
               values_to = "activity_type", values_ptypes = list(factor())) %>% 
  filter(activity_type !=0)-> 
  teempB
  teempB %>%  
  pivot_longer(cols = starts_with("C1_"),names_to = "Hazard_cat",names_prefix = "C1_HazardCat_",
               values_to = "hazard_type", values_ptypes = list(factor())) %>% 
  filter(hazard_type !=0)-> 
  teempC1
  teempC1 %>% 
  pivot_longer(cols = starts_with("C3"),names_to = "Commodity_cat",
                 names_prefix = "C3_CommodityCat_",
                 values_to = "commodity_type", values_ptypes = list(factor())) %>% 
  filter(commodity_type !=0)-> 
  teempC3
  teempC3 %>% 
  pivot_longer(cols = starts_with("D2_"),names_to = "Value_chain",
               names_prefix = "D2_VCPart_",
               values_to = "value_part", values_ptypes = list(factor())) %>% 
  filter(value_part !=0)-> 
  teempD2
  teempD2 %>%  
  pivot_longer(cols = starts_with("D4_"),names_to = "Donor_cat",
               names_prefix = "D4_DonorP_",
               values_to = "Donor_part", values_ptypes = list(factor())) %>% 
  filter(Donor_part !=0)-> 
  teempD4
  teempD4 %>% 
    pivot_longer(cols = 'D6_Non-DonorP_1':'D6_Non-DonorP_9' ,names_to = "NonDonor_cat",
               names_prefix = "D6_Non-DonorP_",
               values_to = "NonDonor_part", values_ptypes = list(factor())) %>% 
   filter(NonDonor_part !=0)-> 
    teempD6
  teempD6 %>% 
      pivot_longer(cols = starts_with("Running in"), names_to = "Years_Ran",
                   names_prefix = "Running in",
                   values_to = "Times_Ran", values_ptypes = list(factor())) %>% 
    filter(Times_Ran !=0)-> 
    fsa2

 #rm(teempA, teempB, teempC1, teempC3, teempD2, teempD4, teempD6)

```

### 3.4 - rename the data frame
```{r}
fsa2 %>%
  rename(B1_Project_focus =  "B1_Project focus",
         Total_budget_USD = "E1_Total_Budget",
         ID_number = "ID number") %>%
   mutate(A8_ImplCat = recode(A8_ImplCat,"1" = "Government",
                          "2" = "University", 
                          "3" = "NGO",
                          "4" = "Church/faith-based",
                          "5" = "Public/private partnership",
                          "6" = "Enterprise", 
                          "7" = "Multilateral",
                          "8" = "Other"),
          A13_TimeFrame = recode(A13_TimeFrame,"1" = "1-4 days",
                          "2" = "5-14 days",
                          "3" = "15-30 days",
                          "4" = ">= 31 days"),
          Activity = recode(Activity, "1" = "Research on hazards & interventions",
                          "2" = "Risk assessment",
                          "3" = "Residue sampling & testing",
                          "4" = "Disease surveillance",
                          "5" = "Legislation/policy/standards development",
                          "6" = "Staff training/certification",
                          "7" = "Regulatory compliance",
                          "8" = "Certification/compliance for export",
                          "9" = "Traceability systems",
                          "10" = "Extension/education/training for private sector enterprises",
                          "11" = "Processing facilities/equipment",
                          "12" = "Transport/cold-chain technology",
                          "13" = "Laboratory facilities/equipment",
                          "14" = "Laboratory methods & training",
                          "15" = "Private audits/certifications",
                          "16" = "Public awareness campaigns",
                          "17" = "Other technical assistance"),
          Commodity_cat = recode(Commodity_cat, "1" = "Cereals",
                          "2" = "Legumes",
                          "3" = "Meat",
                          "4" = "Fish, crustaceans, mollusks",
                          "5" = "Eggs, dairy products",
                          "6" = "Fruits, seeds, tree nuts",
                          "7" = " Vegetables, roots, tubers",
                          "8" = "Cocoa, cocoa preparations",
                          "9" = "Coffee, tea, spices",
                          "10" = "Sugars, sugar confectionary, honey",
                          "11" = "Unspecified"),
          Donor_cat = recode(Donor_cat, "1" = "Multilateral",
                          "2" = "Bilateral",
                          "3" = "Foundation",
                          "4" = "African regional",
                          "5" = "Industry (private only)",
                          "6" = "Public-private partnership",
                          "7" = "Development bank",
                          "9" = "NA"),
          NonDonor_cat = recode(NonDonor_cat, "1" = "Government",
                          "2" = "Universities",
                          "3" = "NGO",
                          "4" = "Church/faith-based",
                          "5" = "Public/private partnerships",
                          "6" = "Enterprises",
                          "7" = "Other",
                          "9" = "NA" ),
          ID_number = parse_factor(ID_number),
         Country = parse_factor(Country, ordered = FALSE)) %>%
         mutate(A11_YearInit = strtoi(A11_YearInit)) %>%
        mutate(A12_YearEnd = strtoi(A12_YearEnd)) %>%
        mutate(A13_TimeFrame = A12_YearEnd - A11_YearInit) -> 
  fsa3

```

### 3.5 - select the columns
```{r}
fsa3 %>%
  select(Country,A8_ImplCat, A11_YearInit:A13_TimeFrame, Activity, Commodity_cat,
         Donor_cat, NonDonor_cat, Total_budget_USD, E2_FSBudget, Category, Hazard_cat) -> 
  fsa4
fsa4_no_dup <- fsa4[!duplicated(fsa4),]

# Country: Country name
# A8_ImplCat: Implementing organization category 
# A11_YearInit: Year initiated
# A12_YearEnd: Year end
# A13_TimeFrame: Time frame of project/activity(If completed in 1 year or less)
# Activity: project activity
# Commodity_cat: Commodity category
# Donor_cat: Donor partner categories 
# NonDonor_cat: Non-donor partner names
# Total_budget_USD: Total budget of project or activity (USD)
# E2_FSBudget: Estimated total budget of food safety activities (USD) within project
# Category: Category 1 and Category 2
# Hazard_cat: Hazard Category

sample_n(fsa4_no_dup,5)

```
```{r}
# teempA %>% 
#   mutate('E!_Total_Budget' = parse_number(str_replace('E!_Total_Budget', "^\\$(\\d*),(\\d*),(\\d*).(\\d*)","\\1\\2\\3.\\4"))) -> teempA2
```

## 4 - Initial Hypotheses
### 4.1.1 Which countries are funded the most and the least?
```{r}
teempA %>%
  group_by(Country) %>% 
summarize(total_budget = sum(E1_Total_Budget, na.rm = TRUE), project = n()) %>%
   arrange(desc(total_budget)) -> Country_desc

head(Country_desc,1)
tail(Country_desc,1)
```

### 4.1.2 Budget vs Number of project in each Country
* Here we create scatter plots and box plots to ascertain if there is a linear relationship.\ 
* Number of projects done per country and Total Funds allocated per country, from this scatter plot. we can see that the countries that got more fundings had more projects, there is a linear relationship between if a country gets more funding.\
```{r, warning=FALSE}
Country_desc %>%
ggplot(aes(x = log(project), y = log(total_budget))) +
  geom_point() +
  geom_smooth(se = FALSE, method = lm) +
  xlab("Number of Project") +
  ylab("Budget (USD)") +
  ggtitle("Budget vs Number of project in each Country") +
  theme_bw()

```

### 4.1.3 - Distribution projects in respect of the country
* we can see each country of project type.
```{r, fig.align = "center", fig.width = 7, fig.height = 3.8}
teempA %>% 
  count(Country, Category) %>% 
  mutate(Country = fct_reorder(Country,-n)) %>% 
  # Sorted by the number with bigger numbers at the front.
 ggplot(aes(x= Country, y = n, fill = Category))+
  geom_col()+
  theme(axis.text.x = element_text(angle = 90))
```

## 5 - Exploratory Data Analysis
### 5.1 - Datasets
#### 5.1.1 - which countries are involved in the project?
* 49 countries
```{r}
Country_desc %>%
  mutate(Country = casefold(Country, upper = FALSE),
         Country = recode(Country, "drc" = "democratic republic of the congo",
                                   "gambia" = "the gambia",
                                   "cote d'ivoire" = "côte d'ivoire",
                                   "congo" = "republic of the congo",
                                   "liberia" = "libya",
                                   "swaziland" = "eswatini",
                                   "car" = "central african republic",
                                   "eq guinea" = "equatorial guinea")) ->
Country_word    
nrow(Country_word)
```

### 5.2 - Data Visualization
#### 5.2.1 - Drawing Africa maps programmatically 
* Obviously, the Africa map is easy to let readers know the association between the number of aid programs and each country.
```{r, message= FALSE, warning = FALSE}
# Get world map data
world <- ne_countries(scale = "medium", returnclass = "sf")
# Add centroid for name labels
world <- cbind(world, st_coordinates(st_centroid(world$geometry)))
# Remove countries not in UN Region for Africa
# # Make all Names upper case
world %>% 
  filter(region_un =="Africa") %>%
  mutate(Country = str_to_upper(admin))->
  world

# find mismatched names across the world data and teempA
left_join(teempA, world) %>% 
  filter(is.na(admin)) %>% 
  select(Country) %>% 
  as.tibble() %>% 
  unique()-> mismatch_country_names
  
  world %>% 
    as.tibble() %>% 
    select(name, Country) %>% 
    anti_join(teempA, by = c("Country"="Country")) ->
    mismatch_wcountry_names

  full_join(mismatch_country_names, mismatch_wcountry_names) %>% 
  arrange(Country) 

  # Clean up mismatched names by changing the world data to confrom to AFS
world %>% 
  mutate(Country = case_when(
    Country == "CAPE VERDE" ~ "CABO VERDE",
    Country == "CENTRAL AFRICAN REPUBLIC" ~ "CAR",
    Country == "DEMOCRATIC REPUBLIC OF THE CONGO" ~ "DRC",
    Country == "REPUBLIC OF CONGO" ~ "CONGO",
    Country == "EQUATORIAL GUINEA" ~ "EQ GUINEA",
    Country == "GUINEA BISSAU" ~ "GUINEA-BISSAU",
    Country == "IVORY COAST" ~ "COTE D'IVOIRE",
    Country == "UNITED REPUBLIC OF TANZANIA" ~ "TANZANIA",
    TRUE ~ Country))->
  world
# Recheck for mismatches
left_join(teempA, world) %>% 
  filter(is.na(admin)) %>% 
  select(Country) %>% 
  as.tibble() %>% 
  unique()-> mismatch_country_names
  
  world %>% 
    as.tibble() %>% 
    
    select(name, Country) %>% 
    anti_join(teempA, by = c("Country"="Country")) ->
    mismatch_wcountry_names
full_join(mismatch_country_names, mismatch_wcountry_names) %>% 
  arrange(Country) 

# sort map element
world %>% 
  select(Country, X, Y, geometry) ->
  world_geom


# Plot with teempA data
teempA%>% 
  group_by(Country) %>% 
  summarize(num_projects = n()) %>% 
  full_join(world_geom) ->
  project_sum
project_sum$num_projects[is.na(project_sum$num_projects)] <- 0

project_sum %>% 
ggplot(aes(fill = project_sum$num_projects)) +
        geom_sf(aes(geometry = geometry)) +
        coord_sf(xlim = c(-24, 54), ylim = c(-37, 38), expand = FALSE) +
        scale_fill_viridis_c(option = "plasma", trans = "sqrt", 
        name = "Number of Projects")+
        geom_text(data= project_sum,aes(x=X, y=Y, label=str_to_title(Country)),
                  color = "pink", fontface = "bold", check_overlap = TRUE) +
        theme(panel.grid.major = 
                element_line(color = gray(0.5), linetype = "dashed",
                             size = 0.5), 
              panel.background = element_rect(fill = "aliceblue"))
```
```{r}
#Data is now cleaned and ready for plotting
# Plot with World data Example
#ggplot(data = world) +
        #geom_sf(aes(fill = gdp_md_est)) +
        #coord_sf(xlim = c(-19, 53), ylim = c(-37, 38), expand = FALSE) +
        #scale_fill_viridis_c(option = "plasma", trans = "sqrt")+
        #geom_text(data= world,aes(x=X, y=Y, label=name),
        #color = "red", fontface = "bold", check_overlap = TRUE) 
```

#### 5.2.2 - The rate at with hazard affects food security in africa in each country
* Here we know that different hazards affects different crops but what are those hazards and how much do they affect security in each country, this shows just that and with it organizations would know how to tailor their plans for specific countries.\
```{r, fig.width = 9}
fsa4_no_dup %>%
  group_by(Hazard_cat, Country) %>%
  summarize(Number_of_hazards = n()) %>%
  ggplot(aes(x = Country, y = log(Number_of_hazards), fill = Hazard_cat)) +
  scale_fill_colorblind(name = "Hazard Category") +
  geom_col() +
  theme(axis.text.x = element_text(angle = 90)) +
  ylab("Number of Hazards") +
  ggtitle("The rate at with hazard affects food security in africa in each country")
```

### 5.2.3 - Which country is vegetarian and non-vegetarian? 
* Here we want to find out which country receives what type of commodity the most.\
```{r, fig.width = 9}
fsa4_no_dup %>%
  group_by(Country, Commodity_cat) %>%
  summarize(Number_of_commodity = n()) %>%
   ggplot(aes(x = Country, y = Number_of_commodity, fill = Commodity_cat)) +
   geom_col() +
   theme(axis.text.x = element_text(angle = 90)) +
   ylab("Amount of produce") +
   ggtitle("Food production per country")
```

### 5.3 - Statistical Inference
#### 5.3.1 - Calculate the positive correlation with medians of Africa population and the Food Safety project. 
* As the project start years are between 2006 to 2018(removed NA). In this case, we download the 2006-2018 Africa area total population from UN data to compare it.\
```{r}
totalpop <- read_csv(file = "./data/africatotalpopulation.csv")

totalpop %>%
  rename("Year" = "Year(s)") %>%
  filter(Variant == "Medium", 
         Year == 2006 | Year == 2007| Year == 2008 | Year == 2009 
         | Year == 2010 | Year == 2011 | Year == 2012 | Year == 2013 
         | Year == 2014 | Year == 2015 | Year == 2016 | Year == 2017 | Year == 2018) %>%
  mutate(Year = factor(Year)) -> africapop

print(africapop)

```
* Choose project start year from Food Safety In Africa data ,and plot\
* The plot seems Food Safety project not deeply help Africa population to increase \
```{r}
teempA %>%
  select(Country, A11_YearInit) %>%
  count(A11_YearInit) %>%
  filter(! is.na(A11_YearInit)) %>%
  rename("Year" = "A11_YearInit","project_year" = "n") %>%
  mutate(Year = factor(Year))-> startyear
  
africapop %>%
  full_join(startyear, by = "Year") -> popandfood

popandfood %>%
  ggplot(aes(x = Value , y = project_year, color = Year)) +
  geom_point()+
  theme_bw()+
  geom_smooth(se = FALSE, color = "blue",method = lm, linetype = "dashed") +
  xlab("Median of a population") +
  ggtitle("Project count & Africa Population") 
  
  
```

### 5.3.2 - Does international investment in food in African countries affect local GDP?
* Now, we want to analyze whether food aid to African countries has an impact on their GDP. First, take the GDP data of all the countries in Africa, and then select the data from 2006 to 2017.\
```{r}
GDP <- read_excel("./data/API_NY.GDP.MKTP.CD_DS2_en_csv_v2_988718.xlsx") %>% 
   select(1,51:62) %>% 
  rename(Country = "Country Name") %>% 
  mutate(Country = casefold(Country,upper = TRUE)) %>% 
  mutate(tot_gdp = `2011`+`2012`+`2013`+`2014`+`2015`+`2016`+`2017`)->
  GDP
head(GDP)
```

* Then, we combine the investment table with the GDP table, and select the countries for which investment data are available.At the same time, rows with missing values and duplicate rows are cleared from the data\ 
```{r}
Country_desc %>% 
  left_join(GDP , by = "Country" ) %>%
  na.omit() %>% 
  select(Country, total_budget, tot_gdp) ->
GDP1
#　duplicated(GDP1) #Make sure there are no duplicate rows.
```
* Finally, as shown in the figure below, the data does not show a significant correlation. Thus, it can be concluded that food investment has no direct bearing on the GDP growth of the countries concerned.\
```{r, fig.align = "center", fig.width = 6, fig.height = 4}
 GDP1 %>%
  ggplot(aes(x = total_budget, y = log(tot_gdp))) +
  geom_point() +
  geom_smooth(se = F) +
  xlab("Budget") +
  ylab("total GDP") +
  ggtitle("Budget vs total GDP of per country") +
  theme_bw ()
   
```

## 6 -  Data-driven Hypotheses
### 6.1 - Here we want to test if our initial hypothesis is true (fail to reject) or not(reject)
```{r, fig.align = "center", fig.width = 6, fig.height = 4}
teempA %>%
  mutate(
    E1_Total_Budget = str_sub(E1_Total_Budget, 2,),
    E1_Total_Budget = parse_number(E1_Total_Budget)
  ) %>%
  group_by(Country, A13_TimeFrame) %>%
  summarize(Budget = sum(E1_Total_Budget, na.rm = TRUE),
            Number_of_project = n()) -> Project1
```

```{r, fig.align = "center", fig.width = 6, fig.height = 4}
ggplot(Project1, aes(x = log(Number_of_project), y = log(Budget), color = A13_TimeFrame)) +
  geom_point() +
  geom_smooth(method = lm, se = F) +
  theme_bw() +
  xlab("Number of Projects") +
  ylab("Budget") +
  ggtitle("Budget vs Number of projects")
```

### 6.2 - Multiple regression on the hypothesis:
```{r}
Project1 %>%
  mutate(Budget = log(Budget), Number_of_project = log(Number_of_project)) -> the_model

the_model %>%
  filter(Budget != -Inf) -> the_model


the_model
Model_1 <- lm(A13_TimeFrame ~ Number_of_project + Budget, the_model)

summary(Model_1)
#plot(Model_1)
```

## 7 - Discussion
  The project of Food Safety in Africa did not magnificently help the Africa population increasing. Therefore, it is recommended that Africa not focus on projects that are not directly linked to food, such as employee training, because this does not play a positive role in their food growth. The investment in food is conducive to the GDP growth of relevant countries.\
  However, if you directly invest money in food, you can increase crop output, stimulate people to increase food consumption, and thus steadily increase GDP. According to the country's level and conditions, it is necessary to formulate a strategy that adapts to its own country. African countries can increase their investment in food and reduce disasters, thereby increasing food production and solving Africa's food problems.\

## 8 - References
* Breman, H., & Debrah, S. (2003). Improving African food security. *SAIS Review, 23(1), 153-170.*\
*Artilce for our reference.*\
* Food Safety in Africa: Past Endeavors and Future Directions.(2019, February 5). Retrieved from <https://datacatalog.worldbank.org/dataset/food-safety-africa-past-endeavors-and-future-directions>\
*This data is the open-source from The World Bank Group collected. The Global Food Safety Partnership's (GFSP) Food Safety in Africa provides an approach to illustrative information on 518 food safety investments in sub-Saharan Africa from 2010 to early 2017.*\
* List of sovereign states and dependent territories in Africa. (2020, April 27). Retrieved from <https://en.wikipedia.org/wiki/List_of_sovereign_states_and_dependent_territories_in_Africa>\
*Africa Countries renamed.*\
* Lovelace, R., Nowosad, J., & Muenchow, J. (2020, April 21). Chapter 8: Making maps with R. Retrieved from <https://geocompr.github.io/geocompkg/articles/solutions08.html>\
*How to create Africa map with the existing dataset.*\
* Mwaniki, A. (2006). Achieving food security in Africa: Challenges and issues. *UN Office of the Special Advisor on Africa (OSAA).*\
*Artilce for our reference.*\
* New GFSP Report Quantifies Food Safety Investment in sub-Saharan Africa. (n.d.). Retrieved from <https://www.gfsp.org/new-gfsp-report-quantifies-food-safety-investment-sub-saharan-africa>\
*Global Food Safety Partnership's website was announced the official information for this data frame. We can download reading guide via this association.*\
* UNdata | explorer. (n.d.). Retrieved from <http://data.un.org/Explorer.aspx?d=PopDiv>\
*Get some quantitative data such as death rates or total population for the countries.*\

