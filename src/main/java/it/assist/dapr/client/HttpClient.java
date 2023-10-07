package it.assist.dapr.client;

import it.assist.dapr.client.model.Order;
import it.assist.dapr.client.model.OrderService;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RestClient;

@Path("/order")
public class HttpClient {

    @RestClient
    OrderService service;

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Consumes(MediaType.APPLICATION_JSON)
    public Response list(){
        return service.getById("http-server","23");
    }
}
