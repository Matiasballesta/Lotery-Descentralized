import React, { Component } from "react";
import smart_contract from "../abis/loteria.json";
import Web3 from "web3";
import Swal from "sweetalert2";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";

import Navigation from "./Navbar";
import MyCarousel from "./Carousel";
import { Container } from "react-bootstrap";

class Tokens extends Component {
  async componentDidMount() {
    // 1. Carga de Web3
    await this.loadWeb3();
    // 2. Carga de datos de la Blockchain
    await this.loadBlockchainData();
  }

  // 1. Carga de Web3
  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      const accounts = await window.ethereum.request({
        method: "eth_requestAccounts",
      });
      console.log("Accounts: ", accounts);
    } else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider);
    } else {
      window.alert("¡Deberías considerar usar Metamask!");
    }
  }

  // 2. Carga de datos de la Blockchain
  async loadBlockchainData() {
    const web3 = window.web3;
    const accounts = await web3.eth.getAccounts();
    this.setState({ account: accounts[0] });
    // Ganache -> 5777, Rinkeby -> 4, BSC -> 97
    const networkId = await web3.eth.net.getId();
    console.log("networkid:", networkId);
    const networkData = smart_contract.networks[networkId];
    console.log("NetworkData:", networkData);

    if (networkData) {
      const abi = smart_contract.abi;
      console.log("abi", abi);
      const address = networkData.address;
      console.log("address:", address);
      const contract = new web3.eth.Contract(abi, address);
      this.setState({ contract });
    } else {
      window.alert("¡El Smart Contract no se ha desplegado en la red!");
    }
  }

  constructor(props) {
    super(props);
    this.state = {
      account: "0x0",
      loading: true,
      contract: null,
      errorMessage: "",
    };
  }

  //Funcion para obtencio nde balance de tokens para el usuario
  _balanceTokens = async () => {
    try {
      console.log("Balance de tokens en ejecucion..");
      const _balance = await this.state.contract.methods
        .balanceTokens(this.state.account)
        .call();
      Swal.fire({
        icon: "info",
        title: "Balance de tokens del usuario...",
        width: 800,
        padding: "3m",
        text: `${_balance} Tokens`,
        backdrop: `rgba(15, 238, 168, 0.2)
      left top
      no-repeat
      `,
      });
    } catch (err) {
      this.setState({ errorMessage: err });
    } finally {
      this.setState({ loading: false });
    }
  };

  _balanceTokensSC = async () => {
    try {
      console.log("Balance de tokens del Smart Contract en Ejecucion");
      const _balanceTokensSC = await this.state.contract.methods
        .balanceTokensSC()
        .call();
      Swal.fire({
        icon: "info",
        title: "Balance de tokens del SC",
        width: 800,
        padding: "3m",
        text: `${_balanceTokensSC} Tokens SC`,
        backdrop: `rgba(15, 238, 168, 0.2)
        left top
        no-repeat
        `,
      });
    } catch (err) {
      this.setState({ errorMessage: err });
    } finally {
      this.setState({ loading: false });
    }
  };

  _balanceEthersSC = async () => {
    try {
      console.log("Balance de Ethers del SC");
      const _balanceEthersSC = await this.state.contract.methods
        .balanceEthers()
        .call();
      Swal.fire({
        icon: "info",
        title: "Balance de Ethers del SC",
        width: 800,
        padding: "3m",
        text: `${_balanceEthersSC}`,
        backdrop: `rgba(15, 238, 168, 0.2)
      left top
      no-repeat
      `,
      });
    } catch (err) {
      this.setState({ errorMessage: err });
    } finally {
      this.setState({ loading: false });
    }
  };

  _compraTokens = async (_numTokens) => {
    try{
      console.log("Compra de tokens en ejecucion")
      const web3 = window.web3
      const ethers = web3.utils.toWei(this._numTokens.value, 'ether')
      await this.state.contract.methods.compraTokens(_numTokens).send({
        from: this.state.account,
        value: ethers
      })
      Swal.fire({
        icon: "success",
        title: "Compra de Token realizada!",
        width: 800,
        padding: "3m",
        text: `Has comprado ${_numTokens} token/s por un valor de ${ethers / 10**18} ether/s`,
        backdrop: `rgba(15, 238, 168, 0.2)
      left top
      no-repeat
      `,
      });
    }catch (err) {
      this.setState({ errorMessage: err });
    } finally {
      this.setState({ loading: false });
   }
  }

_devolverTokens = async (numTokens) => {
  try{
    console.log("Devolucion de tokens ERC-20")
    await this.state.contract.methods.devolverTokens(numTokens).send({
      from: this.state.account
    })
    Swal.fire({
      icon: "warning",
      title: "Devolucion de tokens ERC-20",
      width: 800,
      padding: "3m",
      text: `Has devuelvo ${numTokens} tokens`,
      backdrop: `rgba(15, 238, 168, 0.2)
    left top
    no-repeat
    `,
    });

  }catch (err) {
      this.setState({ errorMessage: err });
    } finally {
      this.setState({ loading: false });
  }
}
  

  render() {
    return (
      <div>
       
        <Navigation account={this.state.account} />
        <MyCarousel />
        <div className="container-fluid mt-5">
          <div className="row">
            <main role="main" className="col-lg-12 d-flex text-center">
              <div className="content mr-auto ml-auto">
                <h1>Gestion de los Tokens ERC-20</h1>
                &nbsp;
                <Container>
                  <Row>
                    <Col>
                      <h3>Tokens User</h3>
                      <form
                        onSubmit={(event) => {
                          event.preventDefault();
                          this._balanceTokens();
                        }}
                      >
                        <input
                          type="submit"
                          className="bbtn btn-block btn-success btn-sm"
                          value="Balance de tokens"
                        ></input>
                      </form>
                    </Col>

                    <Col>
                      <h3>Tokens SC</h3>
                      <form
                        onSubmit={(event) => {
                          event.preventDefault();
                          this._balanceTokensSC();
                        }}
                      >
                        <input
                          type="submit"
                          className="bbtn btn-block btn-info btn-sm"
                          value="Balance de tokens SC"
                        ></input>
                      </form>
                    </Col>

                    <Col>
                      <h3> Ethers SC</h3>
                      <form
                        onSubmit={(e) => {
                          e.preventDefault();
                          this._balanceEthersSC();
                        }}
                      >
                        <input
                          type="submit"
                          className="bbtn btn-block btn-danger btn-sm"
                          value="Balance de Ethers SC"
                        ></input>
                      </form>
                    </Col>
                  </Row>
                </Container>
                    &nbsp;

                    <h3>Compra de Tokens ERC-20</h3>
                    <form 
                    onSubmit={(e) => {
                      e.preventDefault()
                      const cantidad = this._numTokens.value
                      this._compraTokens(cantidad)
                    }}>
                      <input
                      type="number"
                      className="form-control mb-1"
                      placeholder="Cantidad de tokens a comprar"
                      ref={(inp) => this._numTokens = inp}/>

                      <input 
                      type="submit"
                      className="bbtn btn-block btn-primary btn-sm"
                      value="Compra de tokens"/>
                    </form>


                    &nbsp;

                    <h3>Devolucion de Ethers</h3>
                    <form
                    onSubmit={(e) => {
                      e.preventDefault()
                      const amount = this.numTokens.value
                      this._devolverTokens(amount);
                    }}>
                       <input
                      type="number" //No sera un boton si no un number
                      className="form-control mb-1"
                      placeholder="Cantidad de tokens a devolver"
                      ref={(input) => this.numTokens = input}/>
                      
                      <input
                      type="submit" 
                      className="bbtn btn-block btn-warning btn-sm"
                      value="DEVOLVER TOKENS"
                      />
                    </form>

              </div>

            </main>
          </div>
        </div>
      </div>
    );
  }
}

export default Tokens;
               {/* Esta referencia (el input que el usuario va a introducir) va a llamar a 
                      this._numtokens y esto se va a igualar a el input. Cuando el usuario introduce un numero
                      son los tokens que quiere comprar.
                      Cuando se pulse el boton de Submit, se agarra la cantidad puesta en el input que es el 
                  numero de tokens que queremos comprar y se va a generar la compra de tokens llamando a la funcion */}