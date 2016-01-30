# This file uses Google's R naming convention
# https://google.github.io/styleguide/Rguide.xml
library(dplyr)

# Main entry point to run the whole analysis.
RunAnalysis <- function() {
  
  # file path definitions
  basePath <- "./datasets/UCI HAR Dataset"
  trainsetPath <- file.path(basePath, "train/X_train.txt")
  trainActivityPath <- file.path(basePath, "train/Y_train.txt")
  trainSubjectPath <- file.path(basePath, "train/subject_train.txt")
  testsetPath <- file.path(basePath, "test/X_test.txt")
  testActivityPath <- file.path(basePath, "test/Y_test.txt")
  testSubjectPath <- file.path(basePath, "test/subject_test.txt")
  headersPath <- file.path(basePath, "features.txt")
  activityLabelsPath <- file.path(basePath, "activity_labels.txt")
  
  # read activity labels
  lbls <- ReadData(activityLabelsPath)
  trainLbls <- ReadData(trainActivityPath)
  testLbls <- ReadData(testActivityPath)
  
  # merging ids of activities with its labels
  trainLbls$V1 <- lbls[trainLbls$V1, 2]
  testLbls$V1 <- lbls[testLbls$V1, 2]
  
  # append train and test activity labels
  lblsAll <- MergeDfs(trainLbls, testLbls, "activity")
  lblsAll[, "activity"] <- as.factor(lblsAll[, "activity"])
  
  # read subjects
  trainSubjectIds <- ReadData(trainSubjectPath)
  testSubjectIds <- ReadData(testSubjectPath)
  
  # merge train and test subject into one data frame adding column name
  subjectAll <- MergeDfs(trainSubjectIds, testSubjectIds, "subject")
  
  # read feature labels
  headersDf <- ReadData(headersPath)
  headers <- c(headersDf[, 2]) # we are only interested in names
  
  # reading train and test files
  trainDf <- ReadData(trainsetPath)
  testDf <- ReadData(testsetPath)
  
  # merging train and test adding fearture labels as headers
  dfAll <- MergeDfs(trainDf, testDf, headers) %>% # step 1
            ExtractMeanStd %>% # step 2: extract only mean() and std() columns
            cbind(subjectAll) %>% # adding subject column
            cbind(select(lblsAll, activity)) # step 3: adding activity column
  
  # step 4: renaming columns with tidy names
  names(dfAll) <- RenameColumns(names(dfAll))
  
  # step 5: grouping with subject and activity and applying mean to all the numeric columns
  tidyDf <- dfAll %>% group_by(subject, activity) %>% summarise_each(funs(mean))
  
  write.table(format(tidyDf, scientific=T), 
              file = "tidy.txt", 
              row.name=FALSE)
  
  tidyDf
}

# Reads csv file from a given @fromPath
ReadData <- function(fromPath) {
  df <- read.csv(fromPath, sep = "", header = FALSE, stringsAsFactors = FALSE)
  df
}

# Extracts mean and standard deviation columns
ExtractMeanStd <- function(df) {
  df[,grep("(mean\\(\\)|std\\(\\))", names(df))]
}

# Appends train and test data frames together,
# Adds headers name to the data set.
MergeDfs <- function(train, test, headers) {
  dfJoined <- rbind(train, test)
  names(dfJoined) <- headers
  dfJoined
}

# Rename columns names
RenameColumns <- function(name) {
  newName <- gsub("^t", "time", name)
  newName <- gsub("^f", "fequency", newName)
  newName <- gsub("([A]|[B]|[G]|[J]|[M])", "\\.\\1", newName)
  newName <- gsub("Acc", "Accelerometer", newName)
  newName <- gsub("Gyro", "Gyroscope", newName)
  newName <- gsub("Mag", "Magnitude", newName)
  newName <- gsub("\\-", "\\.", newName)
  newName <- gsub("\\(\\)", "", newName)
  tolower(newName)
}