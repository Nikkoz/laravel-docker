### Requirements
* docker
* docker-compose

#### Install Laravel
1. Set env variables in docker.env
2. ```make laravel-install```
3. There may be a problem with folder resolution. Run this: ```sudo chmod a+rw -R ./```  
4. ```make laravel-init```

#### Install from existing repository
1. Set env variables in docker.env
2. ```make laravel-init```
3. In ```/etc/hosts``` set ```127.0.0.1 var_from_VIRTUAL_HOST```

#### Install from existing repository
Manual for XDebug settings in PhpStorm with Docker https://blog.denisbondar.com/post/phpstorm_docker_xdebug
