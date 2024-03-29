# Wireguard VPN Terraform Templates

## What is this project

This repository contains a template which can be used to quickly deploy a Wireguard VPN server as a Digital Ocean VPS (aka. Droplet) using Terraform with two layers of firewalls configured - one through the VPS and the other through Digital Ocean's cloud layer. This template is intended to allow for a Wireguard server to be quickly spun up, such as prior to traveling, to provide a private VPN server to help secure network traffic while abroad at a low cost. Currently, the template utilizes a base-level VPS droplet at a cost of just $4/mo. which includes 500GiB of network traffic. This can easily be changed in the `infrastructure/digitalocean/server.tf` file to increase the VPS resources to correspond to a higher network transfer limit before additional costs apply.

## What is Wireguard

WireGuard is a next-generation VPN technology designed for speed, simplicity, and security. Unlike traditional VPNs, which rely on complex protocols and encryption algorithms, WireGuard uses modern cryptography and a streamlined codebase to deliver faster connection speeds, lower latency, and easier configuration. It's built for the modern age, offering intuitive mobile and desktop applications that make connecting to a VPN as simple as opening an app. This ease of use, combined with its performance and security enhancements, makes WireGuard a compelling choice for individuals and businesses alike.

(Generated by Google's Bard AI)

## What is Terraform

Terraform is an infrastructure as code (IaC) tool that lets you define and manage your infrastructure using human-readable configuration files. This means you can describe your entire infrastructure (cloud servers, networks, security rules, etc.) as code, allowing for version control, collaboration, and consistent deployments. Terraform automates the provisioning and configuration of these resources across multiple cloud providers and on-premises environments, reducing errors and saving time. By managing your infrastructure in code, you gain greater control, agility, and scalability, making Terraform a valuable asset for modern infrastructure management.

(Generated by Google's Bard AI)