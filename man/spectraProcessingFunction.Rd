% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spectraProcessingFunction.r
\name{spectraProcessingFunction}
\alias{spectraProcessingFunction}
\title{Create IDBac SQLite database 
Should work for mzML, mzXML, mgf, and txt data input}
\usage{
spectraProcessingFunction(rawDataFilePath, sampleID, userDBCon)
}
\arguments{
\item{rawDataFilePath}{filepath of the data}

\item{sampleID}{the sample ID to be read and added to the database}

\item{userDBCon}{database connection (checked out pool)}
}
\value{
the peak list modifed by binning then subtractng the matrix sample,
}
\description{
Create IDBac SQLite database 
Should work for mzML, mzXML, mgf, and txt data input
}
