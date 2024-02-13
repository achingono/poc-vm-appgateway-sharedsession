# POC: Azure Virtual Machines, Azure Application Gateway, Azure SQL, Azure Cache for Redis

This repository demonstrates a sample IIS application running in two [Azure Virtual Machines](https://azure.microsoft.com/en-us/products/virtual-machines/), behind a [Azure Application Gateway](https://azure.microsoft.com/en-us/products/application-gateway/) saving data to [Azure Sql Database](https://azure.microsoft.com/products/azure-sql/database), and sharing session state in [Azure Cache for Redis](https://azure.microsoft.com/services/cache).

## Features

- The application is hosted in Windows [Virtual Machines](https://azure.microsoft.com/en-us/products/virtual-machines/), an on-demand, scalable cloud computing Azure service with allocation of hardware, including CPU cores, memory, hard drives, network interfaces, and other devices to run a wide range of operating systems, applications, and workloads in the Azure cloud environment.  
- Data is stored in [Azure Sql Database](https://azure.microsoft.com/products/azure-sql/database), an intelligent, scalable, relational database service built for the cloud, that includes serverless compute.
- Session State is stored in [Azure Cache for Redis](https://azure.microsoft.com/services/cache), a fully managed, in-memory cache that enables high-performance and scalable architectures. Use it to create cloud or hybrid deployments that handle millions of requests per second at sub-millisecond latency—all with the configuration, security, and availability benefits of a managed service.
- Traffic to the virtual machines is managed by [Azure Application Gateway](https://azure.microsoft.com/en-us/products/application-gateway/), a web traffic (OSI layer 7) load balancer that can make routing decisions based on additional attributes of an HTTP request, for example URI path or host headers.
- Secure Access to the virtual machines is made through a point-to-site (P2S) [Azure VPN Gateway](https://azure.microsoft.com/en-us/products/vpn-gateway/), a service that uses a specific type of virtual network gateway to send encrypted traffic between an Azure virtual network and on-premises locations over the public Internet.

## Architecture

Below is the architecture deployed in this demonstration.

## Additional Azure Resources

- **[Azure resource groups](https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal)** are logical containers for Azure resources. You use a single resource group to structure everything related to this solution in the Azure portal.

- **[Azure KeyVault](https://azure.microsoft.com/en-us/products/key-vault/)** is a service that lets you store and safeguard cryptographic keys and other secrets used by cloud apps and services in the cloud. You can use FIPS validated HSMs, import or generate keys in minutes, and monitor and audit your key use with Azure logging and security operations.

- **[Azure Virtual Network](https://azure.microsoft.com/en-us/products/virtual-network/)** is a service that provides the fundamental building block for your private network in Azure. An instance of the service (a virtual network) enables many types of Azure resources to securely communicate with each other, the internet, and on-premises networks.

- **[Azure Private Link](https://azure.microsoft.com/en-us/products/private-link/)** enables access to Azure PaaS Services (for example, SQL Database) over a private endpoint in the virtual network.

- **[Azure Monitor](https://azure.microsoft.com/en-us/products/monitor)**  is a comprehensive monitoring solution for collecting, analyzing, and responding to monitoring data from your cloud and on-premises environments. 