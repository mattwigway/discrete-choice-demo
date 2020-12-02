# Demo of discrete choice modeling using a multinomial logit model with R and Apollo
# Author: Matthew Wigginton Conway <mwconway@asu.edu>
# Prepared for demonstration at the Odum Institute, University of North Carolina at Chapel Hill, 2020-12-03
# Please feel free to adapt this file for your own use. It is licensed under the Unlicense and comitted to the public domain.
# I do not own the copyright on the example data, see http://biogeme.epfl.ch/data.html for reuse guidelines.

# load Apollo choice modeling package
library(apollo)

# This data is from the Biogeme examples, http://biogeme.epfl.ch/data.html
# note that Apollo requires that this variable be called 'database'
database <- read.csv('optima.dat', sep='\t')

# naive computation of estimated walking time based on distance
database$TimeWalk <- database$distance_km / 4 * 60  # 4 km/h, 60 mins in an hour

# listwise deletion of records with missing incomes/modes
database <- subset(database, Income >= 0 & Choice >= 0)

# Initialize the Apollo choice modeling package
apollo_initialise()

# Define model parameters - Apollo will look for the apollo_control variable when running the model
apollo_control <- list(
  # Name for the model/output files
  modelName='ch_mode_choice',
  # description of the model
  modelDescr='Multinomial logit model of mode choice from revealed preference data in Switzerland',
  # Variable in the data 
  indivID='ID' 
)

# define the coefficients/betas. Apollo will estimate these parameters using maximum likelihood
apollo_beta <- c(
  # These are the alternative-specific constants for each mode, alpha in the slides
  asc_walk = 0,
  asc_transit = 0,
  asc_car = 0,
  
  # separate betas for income for each mode
  b_income_walk = 0,
  b_income_transit = 0,
  b_income_car = 0,
  
  # one beta for travel time for each mode
  b_time = 0
)

# not all parameters can be estimated, for identification. Keep asc_walk and b_income_walk
# fixed at zero.
apollo_fixed <- c('asc_walk', 'b_income_walk')

# check all inputs and prepare for model estimation
apollo_inputs <- apollo_validateInputs()

# define the utility functions
apollo_probabilities <- function (apollo_beta, apollo_inputs, functionality='estimate') {
  # attach betas and variables for duration of function execution
  apollo_attach(apollo_beta, apollo_inputs)
  on.exit(apollo_detach(apollo_beta, apollo_inputs))
  
  # define the utility functions
  util <- list(
    walk = asc_walk + b_income_walk * Income + b_time * TimeWalk,
    transit = asc_transit + b_income_transit * Income + b_time * TimePT,
    car = asc_car + b_income_car * Income + b_time * TimeCar
  )
  
  # define model
  mnl_settings <- list(
    # map named alternatives to codes in Choice variable
    alternatives = c(transit=0, car=1, walk=2),
    # All alternatives are available to all decisionmakers
    avail = list(car=rep(1, length(Choice)), transit=rep(1, length(Choice)), walk=rep(1, length(Choice))),
    choiceVar = Choice,
    # utility function
    V = util
  )
  
  # specify that we are estimating a multinomial logit model
  probs <- list(
    model = apollo_mnl(mnl_settings, functionality)
  )
  
  # multiply probabilities across decisionmakers
  probs <- apollo_panelProd(probs, apollo_inputs, functionality)
  
  # finalize model
  return(apollo_prepareProb(probs, apollo_inputs, functionality))
}

# estimate model
result <- apollo_estimate(apollo_beta, apollo_fixed, apollo_probabilities, apollo_inputs)

# print result table
round(
  cbind(
    Coefficient=result$estimate,
    'Standard Error'=result$se,
    'p-value'=pt(-abs(result$estimate / result$se), nrow(database) - length(result$estimate) - 1) * 2
    ), 
3)
