# Provably random raffle contract

## How does it work

1. Users can enter by paying the fees to gain a ticket

2. After X period of time, the lottery will automatically draw a winner

3. Using Chainlink VRF to generate truly random numbers and Chainlink Automation for a time-based trigger

## PLEDGE(DO NOT SKIP!)

<b>I solemnly swear, that I will never place a private key or secret phrase or mnemonic in a .env file that is associated with real funds.

I will only place private keys in a .env file that have ONLY testnet ETH, LINK, or other cryptocurrencies.

When I'm testing and developing, I will use a different wallet than the one associated with my real funds.

I am aware that if I forget a .gitignore and push my key/phrase up to GitHub even for a split-second, or show my key/phrase to the internet for a split second, it should be considered compromised and I should move all my funds immediately.

If I am unsure if my account has real funds in it, I will assume it has real funds in it. If I assume it has real funds in it, I will not use it for developing purposes.

I am aware that even if I hit add account on my metamask (or other ETH wallet) I will get a new private key, but it will share the same secret phrase/mnemonic of the other accounts generated in that metamask (or other ETH wallet). </b>

## Getting Started

### Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

### Quickstart
<br>
1. Fork/ clone this repository
<br>

```
git clone git@github.com:Aaryan-Urunkar/smart-contract-raffle.git
```
<br>
2. Run the following command to compile foundry project
<br>

``` 
  forge build
```
<br>
3. Setup your .env file with the following environment variables:
<br>
<ul>
  <li><b>SEPOLIA_RPC_URL</b> You can get this using <a href="https://www.alchemy.com/">Alchemy</a>. Create a new project for Sepolia and under API KEYS copy the HTTPS URL. </li>
  <li><b>PRIVATE_KEY</b> Create a new wallet on <a href="https://chromewebstore.google.com/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=en&pli=1">Metamask</a>. Access the private key, and before pasting it into .env , add a <em>0x</em>.</li>
  <li><b>ETHERSCAN_API_KEY</b> You can create an account on <a href="https://etherscan.io/">Etherscan</a> and easily obtain an API key.</li>
</ul>
<br>
4. Download libraries
<br>

 Install the chainlink library using the command:
 ```
 forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
 ```
 <br>
 Install the foundry-devops library using the commands: 

```
forge install Cyfrin/foundry-devops --no-commit
git rm -rf lib/forge-std
rm -rf lib/forge-std
forge install foundry-rs/forge-std@v1.8.2 --no-commit
```
<br>
Install solmate mocks using the following command: 

```
forge install transmissions11/solmate
```

<br>
5. Paste this in your foundry.toml

```
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/" , "@solmate/=lib/solmate/src/"]

fs_permissions = [
    { access = "read", path = "./broadcast" },
    { access = "read", path = "./reports" },
]
``` 
## Deployment
### Local Network

To deploy to local network , follow the following commands:

```
anvil
```
<br>
Note the address and port of the local network( ex: 127.0.0.1:8545 ). On a new terminal, run the following commands:

```
forge script script/DeployRaffle.s.sol:DeployRaffle --broadcast --rpc-url https://(ANVIL LOCALHOST NETWORK) --private-key (ANY ANVIL PRIVATE KEY)  
```
<br>
You have successfully deployed your contract locally
<br>

### Sepolia Testnet
To deploy to Sepolia testnet, use the following commands

```
source .env
forge script script/DeployRaffle.s.sol:DeployRaffle --broadcast --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify  
```
