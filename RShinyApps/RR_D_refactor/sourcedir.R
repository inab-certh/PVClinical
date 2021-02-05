
SOURCEDIR <- '../sharedscripts/'
# if (!dir.exists(SOURCEDIR))
#   {
#     SOURCEDIR <- 'sharedscripts/'
# }
if (!file.exists( paste0( SOURCEDIR, 'serverhelpers.R') ))
{
  SOURCEDIR <- 'sharedscripts/'
}
source( paste0( SOURCEDIR, 'prr2_refactor.R') )
source( paste0( SOURCEDIR, 'helpfunctions.r') )
#source( paste0( SOURCEDIR, 'buildurlfun2.R') )
source( paste0( SOURCEDIR, 'serverhelpers.R') )
source( paste0( SOURCEDIR, 'uihelpers.R') )
source( paste0( SOURCEDIR, 'getters_refactor.R') )
source( paste0( SOURCEDIR, 'jstats.R') )
source( paste0( SOURCEDIR, 'LRTShare.R') )

getwhich <- function() {
  return('D')
}
getappname <- function() {
  return('RR_D_refactor')
}