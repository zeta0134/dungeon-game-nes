<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.0" name="technical" tilewidth="16" tileheight="16" tilecount="17" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <image width="16" height="16" source="blank.png"/>
 </tile>
 <tile id="1" type="exit">
  <image width="16" height="16" source="exit.png"/>
 </tile>
 <tile id="2" type="entrance">
  <properties>
   <property name="index" type="int" value="1"/>
  </properties>
  <image width="16" height="16" source="entrance_1.png"/>
 </tile>
 <tile id="3" type="entrance">
  <properties>
   <property name="index" type="int" value="2"/>
  </properties>
  <image width="16" height="16" source="entrance_2.png"/>
 </tile>
 <tile id="4" type="entrance">
  <properties>
   <property name="index" type="int" value="3"/>
  </properties>
  <image width="16" height="16" source="entrance_3.png"/>
 </tile>
 <tile id="5" type="entrance">
  <properties>
   <property name="index" type="int" value="4"/>
  </properties>
  <image width="16" height="16" source="entrance_4.png"/>
 </tile>
 <tile id="6" type="entrance">
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
 <tile id="12">
  <properties>
   <property name="collision_variant" type="int" value="5"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_right_upper.png"/>
 </tile>
 <tile id="13">
  <properties>
   <property name="collision_variant" type="int" value="4"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_right_lower.png"/>
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
 <tile id="14">
  <properties>
   <property name="collision_variant" type="int" value="8"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_up_lower.png"/>
 </tile>
 <tile id="15">
  <properties>
   <property name="collision_variant" type="int" value="9"/>
  </properties>
  <image width="16" height="16" source="shallow_ramp_up_upper.png"/>
 </tile>
 <tile id="16" type="trigger">
  <image width="16" height="16" source="trigger.png"/>
 </tile>
</tileset>
