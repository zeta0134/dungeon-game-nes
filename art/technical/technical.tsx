<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.9" tiledversion="1.9.2" name="technical" tilewidth="16" tileheight="16" tilecount="12" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <image width="16" height="16" source="blank.png"/>
 </tile>
 <tile id="1" class="exit">
  <image width="16" height="16" source="exit.png"/>
 </tile>
 <tile id="2" class="entrance">
  <properties>
   <property name="index" type="int" value="1"/>
  </properties>
  <image width="16" height="16" source="entrance_1.png"/>
 </tile>
 <tile id="3" class="entrance">
  <properties>
   <property name="index" type="int" value="2"/>
  </properties>
  <image width="16" height="16" source="entrance_2.png"/>
 </tile>
 <tile id="4" class="entrance">
  <properties>
   <property name="index" type="int" value="3"/>
  </properties>
  <image width="16" height="16" source="entrance_3.png"/>
 </tile>
 <tile id="5" class="entrance">
  <properties>
   <property name="index" type="int" value="4"/>
  </properties>
  <image width="16" height="16" source="entrance_4.png"/>
 </tile>
 <tile id="6" class="entrance">
  <properties>
   <property name="index" type="int" value="0"/>
  </properties>
  <image width="16" height="16" source="spawn.png"/>
 </tile>
 <tile id="7">
  <properties>
   <property name="collision_variant" type="int" value="1"/>
  </properties>
  <image width="16" height="16" source="steep_ramp_left.png"/>
 </tile>
 <tile id="8">
  <properties>
   <property name="collision_variant" type="int" value="2"/>
  </properties>
  <image width="16" height="16" source="steep_ramp_right.png"/>
 </tile>
 <tile id="9">
  <properties>
   <property name="collision_variant" type="int" value="3"/>
  </properties>
  <image width="16" height="16" source="steep_ramp_up.png"/>
 </tile>
 <tile id="10">
  <properties>
   <property name="collision_variant" type="int" value="6"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_left_lower.png"/>
 </tile>
 <tile id="11">
  <properties>
   <property name="collision_variant" type="int" value="7"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_left_upper.png"/>
 </tile>
</tileset>
