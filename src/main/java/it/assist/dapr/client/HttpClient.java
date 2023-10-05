package it.assist.dapr.client;

import it.assist.dapr.client.model.Order;
import it.assist.dapr.client.model.OrderService;
import it.assist.dapr.mqtt.MqttPublisher;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@Path("/http/client")
public class HttpClient {

    @RestClient
    OrderService service;
    @Inject
    MqttPublisher mqttPublisher;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Consumes(MediaType.APPLICATION_JSON)
    public Response list(){
        mqttPublisher.sendTemperature("23 gradi");
        return Response.ok().build();
//        return service.getById("http-server","23");
    }
}
