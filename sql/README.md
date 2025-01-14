## mariaDBの構築
* minecraftのプラグイン機能群のバックグラウンドとしてSQLを使用する場合があるため、本項で記載する。
* 初期セットアップ
  * 以下のscript実行により一括実行　[script](https://github.com/maron-gt123/k8s-setup-for-proxmox/blob/main/sql/setup.sh)
      * apt updateの実行
      * ntpサーバの指定
      * timezoneの設定
      * mariaDBのインストール
      * Apache2のインストール
      * phpのインストール
      * influxdbのインストール
* mariadbの初期設定
  * 初期設定については手動で設定する。※意図的な変更も加味して
    * 対話型で設定とする
    
          mysql_secure_installation
    * Enter current password for root (enter for none):
      * Ente入力
    * Switch to unix_socket authentication [Y/n]
      * noを入力
    * Change the root password? [Y/n]
      * yesを入力 任意のパスワードを入力
    * Remove anonymous users? [Y/n]
      * yesを入力
    * Disallow root login remotely? [Y/n]
      * yesを入力
    * Remove test database and access to it? [Y/n]
      * yesを入力
    * Reload privilege tables now? [Y/n]
      * yesを入力
* phpmyadminのインストール
  
      apt -y install phpmyadmin
  * apache2を選択
    * 以降すべての内容Yesで設定 
  * apache2.configの編集
  
        cat >> /etc/apache2/apache2.conf << EOF
        
        # phpmyadmin set
        Include /etc/phpmyadmin/apache.conf
        EOF
        
  * PHP-FPMの編集
    */etc/apache2/sites-available/default-ssl.conf 
  
         # </VirtualHost> </VirtualHost>間に記載
                <FilesMatch \.php$>
                    SetHandler "proxy:unix:/var/run/php/php8.3-fpm.sock|fcgi://localhost/"
                </FilesMatch>
  * 設定反映
 
        a2enmod proxy_fcgi setenvif
        a2enconf php8.3-fpm
        systemctl restart php8.3-fpm apache2
  * mariadb 50-server.cnfの編集
  
        nano /etc/mysql/mariadb.conf.d/50-server.cnf
        # 以下コメントアウト
        bind-address            = 127.0.0.1
* 権限関連
  * 本番環境としてはminecraftのユーザー管理及びインベントリ管理、powerdnsのバックエンドDBとして機能させるため2つのユーザーを作成します。
  * mariaDBへのログイン
  
        mysql -u root -p
  * minecraftデータ管理用
    * 新規ユーザ設定

          CREATE USER '<任意のユーザ名>'@'%' IDENTIFIED BY '<任意のパスワード>' ;
    * 新規ユーザに権限付与
  
          GRANT ALL ON *.* to <任意のユーザ名>@'%' ;

  * powerdnsデータ管理用
    * DB作成

           CREATE DATABASE powerdns;
           CREATE DATABASE mc_LuckPerms;
           CREATE DATABASE mc_inventory;
    * 新規ユーザ設定

          CREATE USER '<任意のユーザ名>'@'<powerdnsホストアドレス>' IDENTIFIED BY '<任意のパスワード>' ;
    * 新規ユーザに権限付与
  
          GRANT ALL PRIVILEGES ON powerdns.* TO '<任意のユーザ名>'@'<powerdnsホストアドレス>';
  * 権限反映
    
        FLUSH PRIVILEGES;
  * ログアウト

        exit;
  * データベースのインポート
  
        mysql -u root -p powerdns < /usr/share/doc/pdns-backend-mysql/schema.mysql.sql
