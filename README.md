Getting and Cleaning Data Course Project
========================================

The purpose of this project is to demonstrate the ability to collect, work with, and clean a data set using R.

## About the dataset

This work is based on the "Human Activity Recognition Using Smartphones Dataset" Version 1.0 : http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

## Files in the project

The project contains the following files:

* `./datasets/UCI HAR Dataset`: Human Activity Recognition Using Smartphones Dataset Version 1.0.
* `README.md`: description of the steps for perfoming the dataset analysis. 
* `CodeBook.md`: indicate all the variables and summaries calculated, along with units, and any other relevant information.
* `run_analysis.R`: R scripts performing the analysis on the dataset.

## Run the analysis of the dataset

In order to perfom the analysis of the "Human Activity Recognition Using Smartphones Dataset" you need to run the `run_analysis.R` R script. For that you need to call the function `RunAnalysis()`. The analysis will perform the following steps:

1. Merges the training and the test sets to create one data set.
1. Extracts only the measurements on the mean and standard deviation for each measurement.
1. Uses descriptive activity names to name the activities in the data set
1. Appropriately labels the data set with descriptive variable names.
1. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

### Additional libraries

The script uses `dplyr` library

```r
library(dplyr)
```

### Fast getting started

All you need to do is to run the `run_analysis.R` script.

```r
source("run_analysis.R")
RunAnalysis()
```
The scripts writes a `tidy.txt` which is the result of the cleaning of the initial Human Activity Recognition Using Smartphones Dataset. The output file containis 180 rows and 68 columns. The description of the data in the file can be found in the [CodeBook.md](https://github.com/tjaskula/datasciencecoursera/blob/master/Assignment%20-%20Getting%20and%20Cleaning%20Data%20Course%20Project/CodeBook.md) file.

### Detailed analysis steps

The `run_analysis.R` script performs the following analysis steps

#### Initialization of paths

First, all paths to files that have to be merged together must be initialized. This is the very first part of the script.

```r
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
```
#### Reading datasets from files

The read function is definied as follows:

```r
# Reads csv file from a given @fromPath
ReadData <- function(fromPath) {
  df <- read.csv(fromPath, sep = "", header = FALSE, stringsAsFactors = FALSE)
  df
}
```

Read activity labels from train and test sets and transforming it :

```r
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

``` 

Reading subjects and transforming it:

```r
# read subjects
trainSubjectIds <- ReadData(trainSubjectPath)
testSubjectIds <- ReadData(testSubjectPath)

# merge train and test subject into one data frame adding column name
subjectAll <- MergeDfs(trainSubjectIds, testSubjectIds, "subject")
```

Reading feature labels:

```r
# read feature labels
headersDf <- ReadData(headersPath)
headers <- c(headersDf[, 2]) # we are only interested in names
```

Reading train and test sets

```r
# reading train and test files
trainDf <- ReadData(trainsetPath)
testDf <- ReadData(testsetPath)
```

#### Step 1, 2 and 3

Step 1: Merges the training and the test sets to create one data set.

Step 2: Extracts only the measurements on the mean and standard deviation for each measurement.

Step 3: Uses descriptive activity names to name the activities in the data set

The 3 first steps of the taks are carried out with the following pipline of function using `dplyr` chain operator `%>%`:

```r
# merging train and test adding fearture labels as headers
dfAll <- MergeDfs(trainDf, testDf, headers) %>% # step 1
        ExtractMeanStd %>% # step 2: extract only mean() and std() columns
        cbind(subjectAll) %>% # adding subject column
        cbind(select(lblsAll, activity)) # step 3: adding activity column
```

First in the Step 1, we merge the train and the test data sets with the following function:

```r
# Appends train and test data frames together,
# Adds headers name to the data set.
MergeDfs <- function(train, test, headers) {
  dfJoined <- rbind(train, test)
  names(dfJoined) <- headers
  dfJoined
}
```

Step 2 extracts the mean() and std() columns:

```r
# Extracts mean and standard deviation columns
ExtractMeanStd <- function(df) {
  df[,grep("(mean\\(\\)|std\\(\\))", names(df))]
}
```

Step 3 adds subject and activity columns:

```r
cbind(subjectAll) %>% # adding subject column
cbind(select(lblsAll, activity)) # step 3: adding activity columns
```

#### Step 4

Step 4: Appropriately labels the data set with descriptive variable names.

It renames column that match the tidy definition (readable and clear meaning).

```r
# step 4: renaming columns with tidy names
names(dfAll) <- RenameColumns(names(dfAll))
```

The rename column function is definied as follows:

```r
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
```

#### Step 5

Step 5: From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

```r
# step 5: grouping with subject and activity and applying mean to all the numeric columns
tidyDf <- dfAll %>% group_by(subject, activity) %>% summarise_each(funs(mean))
```

Finally the tidy dataset is written:

```r
write.table(format(tidyDf, scientific=T), 
              file = "tidy.txt", 
              row.name=FALSE)
```

## The full code
The full script code is here : [run_analysis.R](https://github.com/tjaskula/datasciencecoursera/blob/master/Assignment%20-%20Getting%20and%20Cleaning%20Data%20Course%20Project/run_analysis.R)