SigninLogs
| where TimeGenerated >= ago(30d)
| extend  locationString= strcat(tostring(LocationDetails["countryOrRegion"]), "/", tostring(LocationDetails["state"]), "/", tostring(LocationDetails["city"]), ";")
| project TimeGenerated, AppDisplayName , UserPrincipalName, locationString
| make-series dLocationCount = dcount(locationString) on TimeGenerated in range(startofday(ago(30d)),now(), 1d)
by UserPrincipalName, AppDisplayName
| extend (RSquare,Slope,Variance,RVariance,Interception,LineFit)=series_fit_line(dLocationCount)
| where Slope >0.3
