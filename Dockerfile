#Imagen base
FROM node:16.13.1

#Directorio de trabajo
WORKDIR /user/src/app

#Copia del codigo dentro del contenedor
COPY . . 

#Instalacion de los modulos
RUN npm install package.json
RUN npm install -g truffle@5.5.9

#Exposicion de un puerto del contenedor
EXPOSE 3000

#Entrypoint para la ejecucion de la dapp
ENTRYPOINT [ "sh"]