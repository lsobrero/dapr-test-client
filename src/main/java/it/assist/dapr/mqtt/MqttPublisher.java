package it.assist.dapr.mqtt;

import io.smallrye.reactive.messaging.annotations.Broadcast;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.eclipse.microprofile.reactive.messaging.Message;

import java.util.concurrent.CompletionStage;

@ApplicationScoped
public class MqttPublisher {
    @Inject
    @Channel("device-temp")
    @Broadcast
    Emitter<String> emitter;

    public void sendTemperature(String temperature){
        System.out.printf("emitter sending temperature: " + temperature);
        CompletionStage<Void> acked = emitter.send(temperature);
        acked.toCompletableFuture().join();

    }
}
