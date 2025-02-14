This is sample code, for non-production usage. 
You should work with your security and legal teams to meet your organizational security, regulatory and compliance requirements before deployment

# From sensor to the Cloud: Retrofitting of machines with IO-Link and AWS

[![en](https://img.shields.io/badge/lang-en-red.svg)](https://[github.com/jonatasemidio/multilanguage-readme-pattern](https://github.com/aws-samples/retrofitting-with-io-link)/blob/master/README.md)
[![de](https://img.shields.io/badge/lang-de-yellow.svg)](https://github.com/aws-samples/retrofitting-with-io-link/blob/master/README.de.md)

## Hardware requirements
* Pepperl+Fuchs IO-Link master model ICE3-8IOL-G65L-V1D 
* Pepperl+Fuchs IO-Link distance sensor model OMT550-R200-2EP-IO-V1  
  
Both components are also part of the Pepperl+Fuchs 'IO-Link Starter Kit'.

## AWS Setup

![](./img/arch/retro_demo.en.png)

Below setup instructions use AWS CLI.  
If you prefer to build the stack using the console, you can follow these [instructions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html#create-stack) using the Option "Upload template".  
Once created, check the outputs tab of the stack for links to required inputs.

### Create stack
```bash
sh ./deploy.sh -o c
```

### Update stack
```bash
sh ./deploy.sh -o u
```

### Delete stack
```bash
sh ./deploy.sh -o t
```

## Pepperl+Fuchs ICE Setup

* Download IODD for the distance sensor from the [iodd-finder.com](https://ioddfinder.io-link.com/productvariants/search?productName=%22OMT550-R200-2EP-IO-0,3M-V1%22) website
* Connect the master to your powersupply and network. Lookup the manuals of the cables or powersupply if you need further advise. They can be found on the Pepperl+Fuchs website.
* Connect the distance sensor to port 1
* Open the webinterface in your browser by entering the IP adress. The IP to use is printed on the device. In case the default IP cannot be used in your network, lookup how to change default IP in the manual of the device. 
* Upload the IODD .zip file to the device
![](./img/ice3/ice3_iodd.en.png)

* Configure network  
![](./img/ice3/ice3_network.en.png)

* Enable MQTT  
The required certificate and key can be found in the ```./cert``` folder of the project that was created as part of the ```deploy.sh``` script run. The required IoT endpoint will also be outputed by the script.
![](./img/ice3/ice3_mqtt.en.png)

## Validation
In the AWS IoT Sitewise console you now can see the incoming data
![](./img/aws/sitewise.en.png)

You can also use the Sitewise API, e.g. by running following command in AWS CLI to get data of last 5 minutes.
```bash
time_now=$(date +%s)
five_minutes_before=$((time_now - (5 * 60)))

aws iotsitewise get-asset-property-value-history \
  --property-alias "iolinkdata/ice3/port/1/pdi" \
  --start-date $five_minutes_before \
  --end-date $time_now

```

## Possible extensions of architecure
The architecture can be extended in various ways:
* AWS IoT Greengrass enables data processing at the edge before transferring it to AWS Cloud or other applications
* Applications can subscribe to or receive forwarded data
* Data visualization
* Integration of language models via Bedrock Agents
* Use of data in other applications through the SiteWise API
* Data export to Amazon S3 for further use, e.g., through analytics applications
![](./img/arch/retro_demo_extended.en.png)


