#!/bin/bash
#
# A script to deploy GeyserUpdater and Geyser on Spigot, Paper, BungeeCord, Waterfall, and Velocity only for testing purposes.
# It will make multiple directories in the directory it is run in. 


#Directories
pluginCache="PluginCache-guDeploy"
buildTools="BuildTools"
spigotDir="Spigot-guDeploy"
paperDir="Paper-guDeploy"
bungeeDir="Bungeecord-guDeploy"
waterDir="Waterfall-guDeploy"
velocityDir="Velocity-guDeploy"

#Links
guLink="https://ci.projectg.dev/job/GeyserUpdater/job/1.6.0/lastSuccessfulBuild/artifact/target/GeyserUpdater-1.6.0.jar"
geyserLink="https://ci.opencollab.dev/job/GeyserMC/job/Geyser/job/master/821/artifact/bootstrap/"

buildToolsLink="https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
paperLink="https://papermc.io/api/v2/projects/paper/versions/1.17.1/builds/209/downloads/paper-1.17.1-209.jar"
bungeeLink="https://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/bootstrap/target/BungeeCord.jar"
waterLink="https://papermc.io/api/v2/projects/waterfall/versions/1.17/builds/448/downloads/waterfall-1.17-448.jar"
velocityLink="https://versions.velocitypowered.com/download/3.0.0.jar"


echo "[WARN] This script can generate up to 500MB of data!"
echo "[WARN] By running this script, you are agreeing to the mojang EULA"
sleep 5

# Make sure a download command exists
if [[ -x "$(command -v curl)" ]]; then
  downloadCmd='curl'
else
  if [[ -x "$(command -v wget)" ]]; then
    downloadCmd='wget'
  else
    echo "[SEVERE] Failed to find a download command! Install wget or curl."; exit 1
  fi
fi

# Download file for a given link
# first arg is link, second arg is output file name (optional)
download () {
  if [[ "$downloadCmd" == "curl" ]]; then
    if [[ -z "$2" ]]; then
      curl "$1" -O
    else
      curl "$1" --output "$2"
    fi
  else
    if [[ -z "$2" ]]; then
      wget "$1"
    else
      curl "$1" --output-document "$2"
    fi
  fi
}

# Remove existing deployment folders
find . -name "*-guDeploy" -exec rm -r {} +

# Download all plugins and cache them in a folder
getAllPlugins () {
  mkdir "$pluginCache"
  cd "$pluginCache" || exit

  mkdir "Common"
  cd "Common" || exit
  mkdir "GeyserUpdater"
  cd "GeyserUpdater" || exit
  echo
  echo "[INFO] Downloading GeyserUpdater config"
  download "https://raw.githubusercontent.com/ProjectG-Plugins/GeyserUpdater/1.6.0/devconfig.yml" "config.yml"
  cd ../
  echo
  echo "[INFO] Downloading GeyserUpdater"
  download "$guLink"
  cd ../

  mkdir "Spigot"
  cd "Spigot" || exit
  echo
  echo "[INFO] Downloading Geyser-Spigot.jar"
  download "$geyserLink"spigot/target/Geyser-Spigot.jar
  cd ../

  mkdir "BungeeCord"
  cd "BungeeCord" || exit
  echo
  echo "[INFO] Downloading Geyser-BungeeCord.jar"
  download "$geyserLink"bungeecord/target/Geyser-BungeeCord.jar
  cd ../

  mkdir "Velocity"
  cd "Velocity" || exit
  echo
  echo "[INFO] Downloading Geyser-Velocity"
  download "$geyserLink"velocity/target/Geyser-Velocity.jar
  cd ../

  cd ../
}


deploySpigot () {
  echo; echo; echo; echo
  echo "[INFO] Deploying Spigot..."

  # BuildTools shenanigans
  if compgen -G "$buildTools/spigot-*.jar" > /dev/null; then
    echo "[WARN] Using cached spigot jar, delete BuildTools directory if you want to rebuild. "
  else
    if [[ ! -x "$(command -v git)" ]]; then
      echo "[SEVERE] Git is not installed, can't run BuildTools! Skipping Spigot deployment." && return
    fi
    if [[ -d "$buildTools" ]]; then
      rm -r "$buildTools"
    fi
    mkdir "$buildTools"
    cd "$buildTools" || exit
    echo "[INFO] Downloading BuildTools"
    download "$buildToolsLink"
    # unset core.autocrlf according to BuildTools docs
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
    git config --unset core.autocrlf
    fi
    java -Xmx2G -jar BuildTools.jar
    if ! compgen -G "$buildTools/spigot-*.jar" > /dev/null; then
      echo "[SEVERE] Failed to build spigot jar! Skipping spigot deployment!" && cd ../ && return
    fi
    cd ../
  fi

  mkdir "$spigotDir"
  cp "$buildTools"/spigot*.jar "$spigotDir"
  cd "$spigotDir" || exit
  echo "eula=true" >> eula.txt

  mkdir "plugins"
  cd ../
  cp -r "$pluginCache"/Common/* "$spigotDir"/plugins
  cp -r "$pluginCache"/Spigot/* "$spigotDir"/plugins
  cd "$spigotDir" || exit

  java -Xmx2G -jar spigot-*.jar nogui
  cd ../
}

deployPaper () {
  echo; echo; echo; echo
  echo "[INFO] Deploying PaperMC..."
  mkdir "$paperDir"
  cd "$paperDir" || exit
  echo "[INFO] Downloading PaperMC"
  download "$paperLink"
  echo "eula=true" >> eula.txt

  mkdir "plugins"
  cd ../
  cp -r "$pluginCache"/Common/* "$paperDir"/plugins
  cp -r "$pluginCache"/Spigot/* "$paperDir"/plugins
  cd "$paperDir" || exit

  java -Xmx2G -jar paper*.jar nogui
  cd ../
}

deployBungeecord () {
  echo; echo; echo; echo
  echo "[INFO] Deploying BungeeCord"
  mkdir "$bungeeDir"
  cd "$bungeeDir" || exit
  echo "[INFO] Downloading BungeeCord"
  download "$bungeeLink"

  mkdir "plugins"
  cd ../
  cp -r "$pluginCache"/Common/* "$bungeeDir"/plugins
  cp -r "$pluginCache"/BungeeCord/* "$bungeeDir"/plugins
  cd "$bungeeDir" || exit

  java -Xmx512M -jar BungeeCord.jar nogui
  cd ../
}

deployWaterfall () {
  echo; echo; echo; echo
  echo "[INFO] Deploying Waterfall..."
  mkdir "$waterDir"
  cd "$waterDir" || exit
  echo "[INFO] Downloading Waterfall"
  download "$waterLink"

  mkdir "plugins"
  cd ../
  cp -r "$pluginCache"/Common/* "$waterDir"/plugins
  cp -r "$pluginCache"/BungeeCord/* "$waterDir"/plugins
  cd "$waterDir" || exit

  java -Xmx512M -jar waterfall*.jar nogui
  cd ../
}

deployVelocity () {
  echo; echo; echo; echo
  echo "[INFO] Deploying Velocity"
  mkdir "$velocityDir"
  cd "$velocityDir" || exit
  echo "[INFO] Downloading Velocity"
  download "$velocityLink"

  mkdir "plugins"
  cd ../
  cp -r "$pluginCache"/Common/* "$velocityDir"/plugins
  cp -r "$pluginCache"/Velocity/* "$velocityDir"/plugins
  cd "$velocityDir" || exit

  java -Xmx512M -jar ./*.jar nogui
  cd ../
}

getAllPlugins
# deploySpigot
deployPaper
deployBungeecord
deployWaterfall
deployVelocity
rm -r "$pluginCache"

echo "Finished deployment."





