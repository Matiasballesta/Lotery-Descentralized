// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract loteria is ERC20, Ownable{

    //El token erc20 seran los boletos y con el token721 los identificaremos.

    //Direccion del contrato NFT del proyecto
    //Este proyecto tendra un SM por separado a este que se encargara de la gestion de los tokens NFT
    address public nft;

    //Gestion de los Tokens
    constructor() ERC20("Loteria", "JA"){
        _mint(address(this), 100000); //Con el this nos referimos al smart contract y con el address escogemos la direccion del smart contract
        nft = address(new mainERC721()); //Esto creara un nuevo smart contract y solo se hara una vez cuando se haga el deploy del SC.

    }

    //Ganador del premio de la loteria
    address public ganador;

    //Registro del usuario
    //Los usuarios tendrna un SC donde podran realizar mas acciones y ellos seran los OWNERS
    //Le estamos dando unos requisitos de propiedad al usuario. Primero necesitamos un registro de un usuario
    //Y en ese mapping guardaremos la direccion de un usuario enlazada a la direccion de su SC
    mapping(address => address) public usuario_contract;

    //Precio de los tokens ERC-20
    //Que sea internal significa que solo le aparecera al publico y sera PURE por que no queremos que acceda a la blockchain.
    function precioTokens(uint256 _numTokens) internal pure returns (uint256){
        return _numTokens * (1 ether);
    }

    //Funcion para controlar el balance de el token que tenga un usuario
    function balanceTokens(address _acount) public view returns (uint256){
        return balanceOf(_acount);
    }


    //Funcion para controlar el balance de el token ERC20 que tenga el Smart Contract
    function balanceTokensSC() public view returns (uint256){
        return balanceOf(address(this));
    }

    //Visualizacion del balance de Ethers del Smart Contract
    // 1 Ether => 10^18 weis
    function balanceEthers() public view returns (uint256){
        return address(this).balance / 10**18; //Esto devuelve las unidades en Weis
        //Con el / 10**18 pasamos el valor a ethers.
    }

    //Funcion que permita generar nuevos tokens ERC20 del Smart Contract
    /*el SC Ownable tiene caracteristicas referidas al owner del SC que estamos desplegando tiene un
     modifier llamado onlyOwner que hace que unicamente el owner ejecute la generacion de nuevos tokens.*/
    function mint(uint256 _cantidad) public onlyOwner {
        _mint(address(this), _cantidad);
    }

    /* Registro de usuarios
    Smart contract que va a poder gestionar el usuario
    Aca se crea lo que es un Factory, un fn que permite crear otros SM de forma automatica
    y esto es perfecto para que el usuario pueda gestionar dichos SM en todo momento, 
    incluso pasarle de esta manera parametros de entrada */
    function registrar() internal {
        address addr_personal_contract = address(new boletosNFTs(msg.sender, address(this), nft));
        usuario_contract[msg.sender] = addr_personal_contract;
    }

    //Informacion de un usuario
    function usersInfo(address _acount) public view returns (address){
        return usuario_contract[_acount];
    }

    //Funcion compra de Tokens
    function compraTokens(uint256 _numTokens) public payable {
        //Registro del usuario si no lo hizo
        if(usuario_contract[msg.sender] == address(0)){
            registrar();
        }
    //Establecimiento del costo de los tokens a comprar
    uint256 costo = precioTokens(_numTokens);
    //Evaluacion del dinero que el cliente quiere pagar por los tokens
    require(msg.value >= costo, "Compra menos tokens o paga con mas ethers");
    //Obtencion del numero de tokens disponible del SC.
    uint256 balance = balanceTokensSC();
    require(_numTokens <= balance, "Compra un numero menor de tokens");
    //Devolucion del dinero sobrante
    uint256 returnValue = msg.value - costo;
    //El Smart Contract devuelve la cantidad restante
    //.transfer es para enviar ETHERS, es una funcion interna.
    payable(msg.sender).transfer(returnValue);
    //Envio de los tokens al cliente/usuario (_transfer => es una funcion del importe de openzeppeing)
    //_transfer para enviar tokens, funcion de openzeppeling
    _transfer(address(this), msg.sender, _numTokens);

    }

    //Devolucion de tokens al Smart Contract
    function devolverTokens(uint _numTokens) public payable {
        //El numero de tokens debe ser mayor a 0
        require(_numTokens > 0, "Necesitas devolver un numero de tokens mayor a 0");
        //El usuario debe tener esos tokens que quiere devolver
        require(_numTokens <= balanceTokens(msg.sender), "No tienes los tokens que deseas devolver");
        // El usuario transfiere los tokens al Smart Contract 
        _transfer(msg.sender, address(this), _numTokens);
        //El Smart contract envia los ethers al usuario
        //Para enviar dinero a una persona necesitamos que la funcion sea de tipo PAYABLE.
        payable(msg.sender).transfer(precioTokens(_numTokens));
    }

    //GESTION DE LOTERIA ------------------------------------------

    //Precio del boleto de loteria  (en tokens ERC-20) 
    uint public precioBoleto = 5;
    //Relacion: persona que compra los boletos => el numero de los boletos
    mapping(address => uint []) idPersona_boletos;
    //Relacion: boleto => ganador
    mapping(uint => address) ANDBoleto;
    //Numero aleatorio
    uint randNonce = 0;
    //Boletos de la loteria generados
    uint [] boletosComprados;


    //Compra de boletos de loteria
    function compraBoleto(uint _numBoletos) public {
        //Precio total de los boletos a comprar
        uint precioTotal = _numBoletos*precioBoleto;
        //Verificacion de los tokens del usuario
        require(precioTotal <= balanceTokens(msg.sender), "No tienes tokens suficientes");
        //Transferencia de tokens del usuario al Smart Contract
        _transfer(msg.sender, address(this), precioTotal);

        for(uint i = 0; i < _numBoletos; i++){
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
            randNonce++;
            //Almacenamiento de los datos del boleto enlazados al usuario
            idPersona_boletos[msg.sender].push(random);
            //Almacenamiento de los datos de los boletos
            boletosComprados.push(random);
            //Asignacion del AND del boleto para la generacion de un ganador
            ANDBoleto[random] = msg.sender;
            //Creacion de un nuevo NFT para el numero de boleto;
            boletosNFTs(usuario_contract[msg.sender]).mintBoleto(msg.sender, random); 
        }
    }

    //Visualizacion de los boletos del usuario
    function tusBoletos(address _propiertario) public view returns(uint [] memory){
        return idPersona_boletos[_propiertario];
    }

    //Generacion del ganador de la loteria
    function generarGanador() public onlyOwner {
        //Declaracion de la longitud del array
        uint longitud = boletosComprados.length;
        //Verificacion de la compro de al menos de 1 boleto
        require(longitud > 0, "No hay boletos comprados");
        //Eleccion aleatoria de un numero entre: [0-Longitud]
        uint random = uint(uint(keccak256(abi.encodePacked(block.timestamp))) % longitud);
        //Seleccion del numero aleatorio
        uint eleccion = boletosComprados[random];
        //Direccion del ganador de la loteria
        ganador = ANDBoleto[eleccion];
        //Envio del 95% del premio de la loteria al ganador;
        payable(ganador).transfer(address(this).balance * 95 / 100);
        //Envio del 5% del premio al owner de este Smart Contract (que somos nosotros)
        //La funcion owner viene del Smart Contract OWNABLE importado.
        payable(owner()).transfer(address(this).balance * 5 / 100);
    }

}
//Smart contract de NFTs
contract mainERC721 is ERC721 {

    address public direccionLoteria;

    constructor() ERC721("Loteria", "STE"){
        direccionLoteria = msg.sender; //Obteniendo direccion delcontrato principal para hacer un requiere
    }

    //Creacion de NFTs
    //La funcion safeMint ya esta implementada en el SC.
    /* Fn internal del token ERC721, no es publica si no cualquier propietario podria darse boletos 
    pero como esta funcion sera usada en otro contrato, debe ser publica, no funciona siendo internal
    */
    function safeMint(address _propiertario, uint256 _boleto) public {
        require(msg.sender == loteria(direccionLoteria).usersInfo(_propiertario), 
        "No tienes permisos para ejectuar esta funcion");
        _safeMint(_propiertario, _boleto);
    }
}

contract boletosNFTs{

    //Constructor del Smart Contract
    //Datos relevantes del propietario
    struct Owner {
        address direccionPropietario;
        address contratoPadre;
        address contratoNft;
        address contratoUsuario;
    }
    //Estructura de datos de tipo Owner
    Owner public propietario;

    constructor(address _propietario, address _contratoPadre, address _contratoNFT){
      propietario = Owner(_propietario,
                         _contratoPadre,
                         _contratoNFT, 
                        address(this));
    }

    //Conversion de los numeros de los boletos de loteria
    //LLAMANDO A UNA FUNCION DE OTRO CONTRATO PARA NO HACER DE NUEVO LO MISMO
    function mintBoleto(address _propietario, uint _boleto) public {
           require(msg.sender == propietario.contratoPadre, 
        "No tienes permisos para ejecutar esta funcion");
        mainERC721(propietario.contratoNft).safeMint(_propietario, _boleto);
        /*. Primero llamamos al SC de arriba desde el cual usaremos su FN, con su direccion 
        escogeremos su contrato propietario.contractNFT  */
    }
}