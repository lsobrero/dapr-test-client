package it.assist.dapr.client.model;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Response;
import org.eclipse.microprofile.rest.client.inject.RegisterRestClient;

@Path("/order")
@RegisterRestClient(configKey = "order-service")
public interface OrderService {

    @GET
    Response getById(@HeaderParam("dapr-app-id") String daprAppId,@QueryParam("id") String id);
}