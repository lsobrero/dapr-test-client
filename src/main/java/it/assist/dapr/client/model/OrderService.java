package it.assist.dapr.client.model;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

import java.util.Set;

@Path("/order")
@RegisterRestClient(configKey = "order-service")
public interface OrderService {

    @GET
    Response getById(@QueryParam("id") String id);
}