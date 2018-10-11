# Advanced Demo Scenarios

The current **advanced** demo scenario involves the Planespotter application.

## Flavors

There are two sets of configuration here. The Planespotter app under harbor/ will pull its images from harbor-tenant-01.sg.lab/planespotter/. The Planespotter app under original/ will pull from Docker hub when it's added.

## Installing Planespotter

Installing Planespotter requires vSphere Cloud Provider configured.

Then will need to create a namespace `planespotter` and set the default context.

```
kubectl create ns planespotter
kubectl config set-context kubernetes-admin@kubernetes --namespace planespotter
```
Then from here the following kubectl commands:

1. `kubectl create 1-sc-thin.yaml`
2. `kubectl create 2-pvc-mysql.yaml`
3. `kubectl create 3-pod-mysql.yaml`
4. `kubectl create 4-pod-app.yaml`
5. `kubectl create 5-pod-frontend.yaml`
6. `kubectl create 6-pod-redist-asdb.yaml`
7. `kubectl create 7-np-dfw.yaml`

Voila! You can now access your pod at your wildcard address. This should be `planespotter.apps.corp.local` from your jumphost browser.

## About Planespotter

Kudos to Yves Fauser for this app!

Planespotter is composed of a MySQL DB that holds Aircraft registration data from the FAA. You can search through the data in the DB through an API App Server written in Python using Flask. The API App Server is also retrieving data from a Redis in memory cache that contains data from aircrafts that are currently airborne. There's a service written in Python that retrieves the Data about airborne aircrafts and pushes that data into Redis. Finally there is a Frontend written with Python Flask and using Bootstrap.

One of the goals of the Planespotter app is to demonstrate micro-segmentation policies in Kubernetes, Cloud Foundry, vSphere with NSX, etc. Therefore the App is build with this in mind and uses quick timeouts to show the impact of firewall rule changes and includes a 'healtcheck' function that reports back communication issues between the 'microservices' of the app.

Here's the Communication Matrix of the component amongst each other and to the external world:

Here's the Communication Matrix of the component amongst each other and to the external world:

| Component / Source     | Component / Destination       | Dest Port | Notes                               |
|:-----------------------|:------------------------------|:----------|:------------------------------------|
| Ext. Clients / Browser | Planespotter Frontend         | TCP/80    |                                     |
| Ext. Clients / Browser | www.airport-data.com          | TCP/80    | Display Aircraft Thumbnail picture  |
| Planespotter Frontend  | Planespotter API/APP          | TCP/80    | The listening port is configurable  |
| Planespotter API/APP   | Planespotter MySQL	         | TCP/3306  | 									   |
| Planespotter API/APP   | Planespotter Redis	         | TCP/6379  | 									   |
| Planespotter API/APP   | www.airport-data.com          | TCP/80    | Find Aircraft Thumbnail pictures    |
| Planespotter API/APP   | public-api.adsbexchange.com   | TCP/443   | Retrieves latest Aircraft position  |
| ADSB-Sync       		 | www.airport-data.com          | TCP/443   | Retr. Acft. Airbone stat. in poll   |
| ADSB-Sync       		 | www.airport-data.com          | TCP/32030 | Retr. Acft. Airbone stat. in stream |
| ADSB-Sync       		 | Planespotter Redis            | TCP/6379  | 									   |

