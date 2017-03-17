[![Build Status](https://travis-ci.org/striim/azure-solution-template.svg?branch=master)](https://travis-ci.org/striim/azure-solution-template)
[![Code Health](https://landscape.io/github/striim/azure-solution-template/master/landscape.svg?style=flat)](https://landscape.io/github/striim/azure-solution-template/master)
[![Requirements Status](https://requires.io/github/striim/azure-solution-template/requirements.svg?branch=master)](https://requires.io/github/striim/azure-solution-template/requirements/?branch=master)


# Installs Striim Real-time Integration and Analytics Engine Cluster on Azure

## Get Started 
|      | master  |  develop |   
|------|---|---|
| No UI| [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fstriim%2Fazure-solution-template%2Fmaster%2FmainTemplate.json)  |  [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fstriim%2Fazure-solution-template%2Fdevelop%2FmainTemplate.json) |  
| UI   | [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/%7B%22initialData%22%3A%7B%7D%2C%22providerConfig%22%3A%7B%22createUiDefinition%22%3A%22https%3A%2F%2Fraw.githubusercontent.com%2Fstriim%2Fazure-solution-template%2Fmaster%2FcreateUiDefinition.json%22%7D%7D)  | [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#blade/Microsoft_Azure_Compute/CreateMultiVmWizardBlade/internal_bladeCallId/anything/internal_bladeCallerParams/%7B%22initialData%22%3A%7B%7D%2C%22providerConfig%22%3A%7B%22createUiDefinition%22%3A%22https%3A%2F%2Fraw.githubusercontent.com%2Fstriim%2Fazure-solution-template%2Fdevelop%2FcreateUiDefinition.json%22%7D%7D)  | 







## Introduction to Striim
The Striim™ platform makes it easy to create streaming data pipelines – including change data capture (CDC) – for real-time log correlation, cloud integration, IoT edge processing, and streaming analytics.

This template will install any number of CentOS based Striim nodes.

Use the Deploy to Azure button to get started

## Parameters
 * Striim Cluster Name : A unique name for a logical cluster. Node's name would be <clusterName>-node<0-n>
 * Striim Cluster Password : A password for Striim cluster
 * Node Count : Number of nodes required in the cluster
 * Size of Cluster Nodes : Desired size for each node. We suggest to use Standard_DS11_v2
 * Admin Username : Admin username of the VM
 * Admin Password : Admin password of the VM as well as the Striim admin user
 * Company Name : Name of the company to which you belong
 
 
 
