# Test Client


## Compiling 
mvn package -Dquarkus.package.type=uber-jar

## Running on dapr

```shell script
dapr run --app-id http-client --app-protocol http --dapr-http-port 3500 -- java -jar target/client-1.0.0-SNAPSHOT-runner.jar
```


# Test Server


## Compiling
mvn package -Dquarkus.package.type=uber-jar

## Running on dapr

```shell script
dapr run --app-id http-server --app-port 8081 --app-protocol http --dapr-http-port 3501 -- java -jar target/server-1.0.0-SNAPSHOT-runner.jar
```

