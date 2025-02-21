wget https://download.geofabrik.de/europe/czech-republic-latest.osm.pbf -O $(pwd)/czech-republic.osm.pbf

curl https://raw.githubusercontent.com/siwekm/czech-geojson/refs/heads/master/kraje.json | jq '{
  type: "Feature",
  geometry: {
    type: "Polygon",
    coordinates: (.features[] | select(.nationalCode == "19") | .geometry.coordinates)
  },
  properties: {
    name: (.features[] | select(.nationalCode == "19") | .name)
  }
}' > prague.json

osmium extract -p prague.json -o $(pwd)/cz-prague.osm.pbf $(pwd)/czech-republic.osm.pbf


time docker run --rm --name planetiler -ti -e JAVA_TOOL_OPTIONS="-Xmx24g" -v "/data/openmaptiles/data":/data ghcr.io/onthegomap/planetiler:latest ---osm-path=/data/cz-prague.osm.pbf --nodemap-type=array --storage=mmap --output=/data/cz-prague-$(date '+%y%m%d').mbtiles --download --area=czech-republic

docker run --rm -it -v $(pwd)/:/data -p 8888:8080 maptiler/tileserver-gl:latest --file cz-prague-$(date '+%y%m%d').mbtiles


cat << EOF > Dockerfile
FROM maptiler/tileserver-gl:latest
COPY cz-prague-$(date '+%y%m%d').mbtiles /data/tiles.mbtiles
EOF

docker build -t tileserver-gl:cz-prague-$(date '+%y%m%d') .
