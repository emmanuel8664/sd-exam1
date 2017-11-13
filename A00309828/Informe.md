# Examen 1 #

Universidad ICESI
Curso: Sistemas Distribuidos
Docente: Daniel Barragán C.
Tema: Automatización de infraestructura (Vagrant+Chef)
Correo: daniel.barragan at correo.icesi.edu.co

Objetivos

Realizar de forma autónoma el aprovisionamiento automático de infraestructura
Diagnosticar y ejecutar de forma autónoma las acciones necesarias para lograr infraestructuras estables
Integrar servicios ejecutándose en nodos distintos
Prerrequisitos

Vagrant
Box del sistema operativo CentOS 6.5 o superior

Descripción

El stack ELK es un paquete de tres herramientas open source de la empresa Elastic. Las herramientas son Elasticsearch, Logstash y Kibana. Estas tres herramientas son proyectos independientes pero pueden ser usadas en conjunto para desplegar un ambiente de monitoreo de infraestructura.

Deberá	realizar	el	aprovisionamiento	de	un	ambiente	compuesto	por	los	siguientes	elementos: Un servidor encargado de almacenar logs por medio de la aplicación Elasticsearch, un servidor encargado de hacer la conversión de logs por medio de la aplicación Logstash, un servidor con la herramienta encargada de visualizar la información de los logs por medio de la aplicación Kibana, por último uno o varios servidores web ejecutando la aplicación filebeat para el envío de los logs al servidor con Logstash

![elkstack](https://user-images.githubusercontent.com/17281732/32709570-5e9f2e00-c7ff-11e7-9cc0-3525c493c49d.jpg)

***Consigne los comandos de Linux necesarios para el aprovisionamiento de los servicios solicitados. 
En este punto no debe incluir recetas solo se requiere que usted identifique los comandos o acciones que debe automatizar***

elasticsearch_server->192.168.56.1
kibana_server -> 192.168.56.2
logstash_server -> 192.168.56.3
web_server -> 192.168.56.4


Los comandos necesarios para el aprovisionamiento de los servicios solicitados son:

***Servidor Elasticsearch***

__instalar llave publica__ 
```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
__crear archivo para instalacion__
```bash
vi /etc/yum.repos.d/elasticsearch.repo
```
__instalacion__
```bash
sudo yum install elasticsearch
```
__configuracion__

En el archivo /etc/elasticsearch/elasticsearch.yml.
```bash
network.host: 192.168.56.1
http.port: 9200
```


***Servidor Kibana***

__instalar llave publica__ 
```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
__crear archivo para instalacion__
```bash
vi /etc/yum.repos.d/kibana.repo
```
__instalacion__
```bash
sudo yum install kibana
```
__configuracion__

```bash
server.port: 5601
server.host: "192.168.56.2"
elasticsearch.url: "http://192.168.56.1:9200"
```

***Servidor LogsTash***

__instalar llave publica__ 
```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
__crear archivo para instalacion__
```bash
vi /etc/yum.repos.d/logstash.repo
```
__instalacion__
```bash
sudo yum install logstash
```
__configuracion__

```bash
input {
    beats {
        port => "5044"
    }
}
filter {
    grok {
        match => { "message" => "%{COMBINEDAPACHELOG}"}
    }
}
output {
    elasticsearch
    {
        hosts => ["192.168.56.1:9200"]
    }
}
```

***Servidor Filebeat***

__instalar llave publica__ 
```bash
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```
crear archivo para instalacion
```bash
vi /etc/yum.repos.d/elastic.repo
```
__instalacion__
```bash
sudo yum install filebeat
```
__configuracion__
```bash
yum install httpd -y
```

Modificar el archivo /etc/filebeat/filebeat.yml para que utilice los logs de httpd:
```bash
input_type: log
paths:
    - /var/log/httpd/access_log
```

Destino de esos logs (servidor elasticsearch).
```bash
output.logstash:
  hosts: ["192.168.56.101:5044"]
```


***Escriba el archivo Vagrantfile para realizar el aprovisionamiento, teniendo en cuenta definir: maquinas a aprovisionar, 
interfaces solo anfitrión, interfaces tipo puente, declaración de cookbooks, variables necesarias para plantillas***

```ruby
Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  #Servidor que almacena logs
  config.vm.define :elasticsearch_server do |elasticsearch_server|
    
    elasticsearch_server.vm.box = "centos1706_v0.2.0"
    
    elasticsearch_server.vm.network :private_network, ip: "192.168.56.1"
    
    elasticsearch_server.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "elasticsearch_server" ]
    end

    #Aprovisionador (Chef Solo)
    config.vm.provision :chef_solo do |chef|
      
      chef.install = false
     
      chef.cookbooks_path = "cookbooks"
      
      chef.add_recipe "elasticsearch"
      
      chef.json = {"direccion_ip" => "192.168.56.1"}
    end
  end

  #Servidor para kibana 
  config.vm.define :kibana_server do |kibana_server|
    
    kibana_server.vm.box = "centos1706_v0.2.0"
    
    kibana_server.vm.network :private_network, ip: "192.168.56.2"
    
    kibana_server.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "kibana_server" ]
    end

    #Aprovisionador (Chef Solo)
    config.vm.provision :chef_solo do |chef|
      
      chef.install = false
      
      chef.cookbooks_path = "cookbooks"
      
      chef.add_recipe "kibana"
      
      chef.json = {"direccion_ip" => "192.168.56.2", "elasticsearch_url" => "http://192.168.56.1:9200"}

    end


  end

  #Servidor para LogsTash 
  config.vm.define :logstash_server do |logstash_server|
    
    logstash_server.vm.box = "centos1706_v0.2.0"
    
    logstash_server.vm.network :private_network, ip: "192.168.56.3"
    
    logstash_server.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "logstash_server" ]
    end

    #Aprovisionador (Chef Solo)
    config.vm.provision :chef_solo do |chef|
      
      chef.install = false
      
      chef.cookbooks_path = "cookbooks"
      
      chef.add_recipe "logstash"
      
      chef.json = {"direccion_ip" => "192.168.56.1"}
    end
  end

  #Servidor para Filebeat 
  config.vm.define :web_server do |web_server|

    web_server.vm.box = "centos1706_v0.2.0"
   
    web_server.vm.network :private_network, ip: "192.168.56.4"
    
    web_server.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "web_server" ]
    end

    #Aprovisionador (Chef Solo)
    config.vm.provision :chef_solo do |chef|
      
      chef.install = false
      
      chef.cookbooks_path = "cookbooks"
      
      chef.add_recipe "httpd"
      
      chef.add_recipe "filebeat"
      
      chef.json = {"direccion_ip" => "192.168.56.3"}
    end

  end

end

```

***Escriba los cookbooks necesarios para realizar la instalación de los servicios solicitados***

__Elasticsearch__

![1](https://user-images.githubusercontent.com/17281732/32709658-13e4d616-c800-11e7-9aa3-11115ce6f5d8.PNG)

__Filebeat__

![2](https://user-images.githubusercontent.com/17281732/32709677-35966e64-c800-11e7-8576-212b5be87370.PNG)

__Httpd__

![3](https://user-images.githubusercontent.com/17281732/32709687-53f49854-c800-11e7-9c42-f94b1025f15a.PNG)

__Kibana__

![4](https://user-images.githubusercontent.com/17281732/32709711-7efa8464-c800-11e7-8649-9a94aed7ae85.PNG)

__Logstash__

![5](https://user-images.githubusercontent.com/17281732/32709713-8be9b104-c800-11e7-99a5-54383ae5556e.PNG)






***4.Incluya evidencias que muestran el funcionamiento de lo solicitado*** 

__Httpd__
![apache](https://user-images.githubusercontent.com/17281732/32709796-58a2ec42-c801-11e7-8003-e4a33d6d014d.jpeg)

__Registro de Logs con Stack ELK__
![kibana](https://user-images.githubusercontent.com/17281732/32709830-a1083bcc-c801-11e7-9c8d-f0d9a71e002f.jpeg)


***5.Documente algunos de los problemas encontrados y las acciones efectuadas para su solución al aprovisionar la 
infraestructura y aplicaciones***


1)Vagrant me sacaba comentarios rojos y se debía a que los archivos no tenían bien los nombres y no los encontraba. Para solucionar esto tuve que poner bien los nombres.

2)No tenía como verificar que todo estaba funcionando en cada máquina dónde tenía el ELK. Para encontrar errores me tocó meterme a cada maquina a ver
si tenía el servicio corriendo etc.
    





