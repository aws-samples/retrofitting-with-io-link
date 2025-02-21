Dies ist Beispielcode, nicht für den Produktiveinsatz gedacht.
Sie sollten mit Ihren Sicherheits- und Rechtsteams zusammenarbeiten, um die Sicherheits-, Regulierungs- und Compliance-Anforderungen Ihrer Organisation vor der Bereitstellung zu erfüllen.

# Vom Sensor zur Cloud: Nachrüstung von Maschinen mit IO-Link und AWS

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/aws-samples/retrofitting-with-io-link/blob/master/README.md)
[![de](https://img.shields.io/badge/lang-de-yellow.svg)](https://github.com/aws-samples/retrofitting-with-io-link/blob/master/README.de.md)

## Überblick
Diese Demo zeigt, wie man durch die Verbindung eines Pepperl+Fuchs IO-Link Masters mit der AWS Cloud neue digitale Fähigkeiten für bestehende Maschinen und ganze Prozesse generieren kann. Wir registrieren die Daten in AWS IoT SiteWise, einem Service, der für die Aufzeichnung und Analyse von Industriedaten entwickelt wurde.

## Hardware-Anforderungen
* Pepperl+Fuchs IO-Link Master Modell ICE3-8IOL-G65L-V1D 
* Pepperl+Fuchs IO-Link Abstandssensor Modell OMT550-R200-2EP-IO-V1  
  
Beide Komponenten sind auch Teil des Pepperl+Fuchs 'IO-Link Starter Kit'.

## AWS-Einrichtung

![](./img/arch/retro_demo.de.png)

Die folgenden Anweisungen verwenden die AWS CLI.  
Wenn Sie den Stack lieber über die Konsole erstellen möchten, können Sie dieser [Anleitung](https://docs.aws.amazon.com/de_de/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html#create-stack) unter Nutzung der Option "Vorlage hochladen" folgen.  
Nach der Erstellung des Stacks finden Sie im Ausgabe-Tab des Stacks Links zu den erforderlichen Eingaben.

### Stack erstellen
Der folgende Befehl erstellt den Stack, lädt das Zertifikat und den privaten Schlüssel herunter und gibt den zu verwendenden IoT-Endpunkt aus.
> [!TIP]
> Für Produktivszenarien sollten Sie in Erwägung ziehen, [einen eigenen Domainnamen für den Endpunkt zu erstellen](https://docs.aws.amazon.com/de_de/iot/latest/developerguide/iot-custom-endpoints-configurable-custom.html).
```bash
cd demo-setup
sh ./deploy.sh -o c # c = create, u = update, t = delete
cd -
```

### Optional: Erweiterung zur Nutzung von Geräteschatten erstellen
Dieser Stack enthält die Logik um die Status Nachrichten des Masters in Geräteschatten zu persistieren.

![](./img/arch/shadow_addon.de.png)

Um die Erweiterung zu provisionieren nutzen Sie diese Befehle
```bash
cd device-shadow-addon
sh ./deploy.sh -o c # c = create, u = update, t = delete
cd -
```

### Optional: Erweiterung für MQTT-Last-Will
Diese Erweiterung sendet eine E-Mail via Amazon SNS sobald der Broker die Last-Will-Nachricht des Geräts versendet. Dies passiert, wenn die Verbindung unerwartet abreißt.
Vergessen Sie nicht, den Email-Versand durch SNS zu bestätigen. Sie bekommen dazu eine automatische Email sobald die Subscription erzeugt wurde.
![](./img/arch/last_will_addon.de.png)

To provision the addon use these commands
```bash
cd last-will-addon
sh deploy.sh -o c -e INSERT-YOUR-EMAIL # -o: c = create, u = update, t = delete
cd -
```

## Pepperl+Fuchs ICE Einrichtung

* Laden Sie IODD des Distanzsensors von der [iodd-finder.com](https://ioddfinder.io-link.com/productvariants/search?productName=%22OMT550-R200-2EP-IO-0,3M-V1%22) Website herunter
* Verbinden Sie den Master mit Ihrer Stromversorgung und dem Netzwerk. Schauen Sie in die Handbücher der Kabel oder Stromversorgung, wenn Sie weitere Hinweise benötigen. Diese finden Sie auf der Pepperl+Fuchs Webseite
* Verbinden Sie den Abstandssensor mit Port 1
* Öffnen Sie die Weboberfläche in Ihrem Browser durch Eingabe der IP-Adresse. Die zu verwendende IP ist auf dem Gerät aufgedruckt. Falls die Standard-IP in Ihrem Netzwerk nicht verwendet werden kann, lesen Sie im Handbuch des Geräts nach, wie Sie die Standard-IP ändern können
* Laden Sie die IODD .zip-Datei auf das Gerät hoch
![](./img/ice3/ice3_iodd.de.png)

* Netzwerk konfigurieren 
![](./img/ice3/ice3_network.de.png)

* MQTT aktivieren  
Das erforderliche Zertifikat und der Schlüssel befinden sich im ```.demo-setup/cert``` Ordner des Projekts, der im Rahmen der Ausführung des ```deploy.sh``` Skripts erstellt wurde. Der erforderliche IoT-Endpunkt wird ebenfalls vom Skript ermittelt und ausgegeben.
![](./img/ice3/ice3_mqtt.de.png)

## Validieren
Hier ist die deutsche Übersetzung:

Öffnen Sie den [MQTT Test Client](https://console.aws.amazon.com/iot/home?#/test) in der AWS Konsole.  
Stellen Sie sicher, dass Sie sich in der richtigen Region befinden!  
Wählen Sie die Option 'Thema abonnieren' und verwenden Sie ```iolinkdata/ice3``` als Themenfilter.  
Sie sehen nun die eingehenden Sensordaten, hier zum Beispiel eine Probe der Sensormessungen:
```json
{
  "port": 1,
  "valid": 1,
  "uint": 270859269,
  "P_ProcessData0": {
    "MV___Distance": 4132,
    "Scale": -4,
    "SSC1___Switching_Signal_1": true,
    "SSC2___Switching_Signal_2": false,
    "Signal_Quality_Indicator": 1
  },
  "raw": [
    16,
    36,
    252,
    5
  ]
}
```

In der AWS IoT Sitewise Console sind die eingehenden Werte nun zu beobachten.
![](./img/aws/sitewise.de.png)

Alternativ kann auch über die Sitewise API, z.B. via AWS CLI eine Abfrage gestartet werden.  
Diese Abfrage frage z.B. die historischen Werte der letzen 5 Minute ab.
```bash
time_now=$(date +%s)
five_minutes_before=$((time_now - (5 * 60)))

aws iotsitewise get-asset-property-value-history \
  --property-alias "iolinkdata/ice3/port/1/pdi" \
  --start-date $five_minutes_before \
  --end-date $time_now

```

### Stack löschen
```bash
sh ./deploy.sh -o t
```

## Mögliche Erweiterungen der Architektur
Die Architektur lässt sich auf vielfältige Weise erweitern:
* AWS IoT Greengrass ermöglicht es, die Daten am Edge zu prozessieren, bevor sie an die AWS Cloud oder andere Applikationen übergeben werden
* Applikationen können die Daten abonnieren oder weitergeleitet bekommen
* Datenvisualisierung
* Anbindung von Sprachmodellen über Bedrock Agents (beachten Sie dieses Repo: https://github.com/aws-samples/aws-iot-sitewise-conversational-agent)  
* Nutzung der Daten in weiteren Applikationen durch die SiteWise API
* Datenexport nach Amazon S3 zur Weiternutzung z.B. durch Analytics-Applikationen
![](./img/arch/retro_extended.de.png)