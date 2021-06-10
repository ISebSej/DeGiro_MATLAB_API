# Project (Unofficial) DeGiro API for MATLAB

# **Under Contruction **

A simple class to perform basic interactions with DeGiro servers. It is heavily based on other existing projects in different languages.

What works: 

- Login 
- Getting client token 
- Getting Portfolio information and summary

What is not implemented yet: 
- Pretty much everything else 
- Getting order and transaction history 
- Getting ask/bid spreads
- Placing orders 
- Etc.

## How to use

```sh
%% Initialize the API instance
degiro = DeGiroAPI();

%% Your credentials
usr = "Your Username";
pwd = "Your_Password"

%% Log in
%% All of your information will be visible inside the degiro struct
degiro.Login(usr, pwd);

%% Get your portfolio information
degiro.GetPortfolio();

%% View all active assets
disp(degiro.portfolio.active)
```

## How to contribute?
Just write new methods or improve existing ones and send in a your merge request.
This is a small project I do in my free time, so use at your own discretion. 
