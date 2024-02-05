--create table

CREATE TABLE buildings (
	ogc_fid serial4 NOT NULL,
	id varchar NOT NULL,
	buildingpart varchar NULL,
	json_attributes jsonb NULL,
	wkb_geometry public.geometry NULL,
	color varchar NULL,
	CONSTRAINT buildings_pkey PRIMARY KEY (ogc_fid)
);
CREATE INDEX buildings_st_centroid_idx ON buildings USING gist (st_centroid(st_envelope(wkb_geometry)));
--extraction of geometries from json to target table buildings (table city_object created by cjdb)
-- roof
with bomb as (select object_id, 
	unnest(array(select jsonb_array_elements(geometry -> -1 -> 'boundaries' ->-1  ))) as exploded,
unnest(array(select jsonb_array_elements(geometry -> -1 -> 'semantics' -> 'values'->-1))) as sem
	from city_object co where type = 'BuildingPart'), 
dynamite as (select bomb.object_id, bomb.exploded[0]||jsonb_build_array(bomb.exploded[0][0]) as magic from bomb where sem = '1'), 
geom as (select object_id,   ST_GeomFromText('MULTIPOLYGONZ('||replace(replace(replace(replace(replace(array_to_string(array_agg( magic), ':'), ',',''), ']]:[[', ')),(('), '] [', ','), '[[', '(('), ']]','))')||')',2154)
 as lod22 from dynamite group by object_id), 
toot as (select lod22, geom.object_id, city_object.attributes from geom, city_object where  city_object.object_id = geom.object_id)
INSERT INTO buildings(id, buildingpart, json_attributes, wkb_geometry) select toot.object_id, 'roof', toot.attributes, toot.lod22 from toot;

--floor
with bomb as (select object_id, 
	unnest(array(select jsonb_array_elements(geometry -> -1 -> 'boundaries' ->-1  ))) as exploded,
unnest(array(select jsonb_array_elements(geometry -> -1 -> 'semantics' -> 'values'->-1))) as sem
	from city_object co where type = 'BuildingPart'), 
dynamite as (select bomb.object_id, bomb.exploded[0]||jsonb_build_array(bomb.exploded[0][0]) as magic from bomb where sem = '0'), 
geom as (select object_id,   ST_GeomFromText('MULTIPOLYGONZ('||replace(replace(replace(replace(replace(array_to_string(array_agg( magic), ':'), ',',''), ']]:[[', ')),(('), '] [', ','), '[[', '(('), ']]','))')||')',2154)
 as lod22 from dynamite group by object_id), 
toot as (select lod22, geom.object_id, city_object.attributes from geom, city_object where  city_object.object_id = geom.object_id)
INSERT INTO buildings(id, buildingpart, json_attributes, wkb_geometry) select toot.object_id, 'floor', toot.attributes, toot.lod22 from toot;

--wall
with bomb as (select object_id, 
	unnest(array(select jsonb_array_elements(geometry -> -1 -> 'boundaries' ->-1  ))) as exploded,
unnest(array(select jsonb_array_elements(geometry -> -1 -> 'semantics' -> 'values'->-1))) as sem
	from city_object co where type = 'BuildingPart'), 
dynamite as (select bomb.object_id, bomb.exploded[0]||jsonb_build_array(bomb.exploded[0][0]) as magic from bomb where sem = '2' or sem = '3'), 
geom as (select object_id,   ST_GeomFromText('MULTIPOLYGONZ('||replace(replace(replace(replace(replace(array_to_string(array_agg( magic), ':'), ',',''), ']]:[[', ')),(('), '] [', ','), '[[', '(('), ']]','))')||')',2154)
 as lod22 from dynamite group by object_id), 
toot as (select lod22, geom.object_id, city_object.attributes from geom, city_object where  city_object.object_id = geom.object_id)
INSERT INTO buildings(id, buildingpart, json_attributes, wkb_geometry) select toot.object_id, 'wall', toot.attributes, toot.lod22 from toot;