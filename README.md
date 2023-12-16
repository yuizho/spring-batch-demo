## Getting Started

```
$ ./mvnw clean spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.profiles.active=dev -Ds3.url.person-data-csv=s3://test-bucket/test-bucket/csv/sample-data.csv"
```