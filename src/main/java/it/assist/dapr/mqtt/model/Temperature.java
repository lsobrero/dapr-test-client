package it.assist.dapr.mqtt.model;

import lombok.Data;

import java.io.Serializable;

@Data
public class Temperature implements Serializable {
    private static final long serialVersionUID = 1L;

    String deviceName;
    String city = "TO";
    String temperature = "23";

    public Temperature(String deviceName) {
        this.deviceName = deviceName;
    }
}
