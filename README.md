## Getting Started

```
$ ./mvnw clean spring-boot:run -Dspring-boot.run.arguments="run.id=$(date '+%s')" -Dspring-boot.run.jvmArguments="-Dspring.profiles.active=dev"
```