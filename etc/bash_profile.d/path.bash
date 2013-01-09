if [ -d /opt/bin ]; then
  PATH="/opt/bin:$PATH"
fi
if [ -d /opt/share/npm/bin ]; then
  PATH=/opt/bin:$PATH
fi

if ! { which node > /dev/null; } && [ -d /node ]; then
  echo "looking for node" 
fi

export PATH
