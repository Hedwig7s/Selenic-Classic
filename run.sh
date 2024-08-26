set -e
./build.sh
cd build
luvit main.lua
cd ..