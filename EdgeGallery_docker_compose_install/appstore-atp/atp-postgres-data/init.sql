DROP TABLE IF EXISTS TASK_TABLE;

CREATE TABLE TASK_TABLE (
    ID                       VARCHAR(200)       NOT NULL,
    APPNAME                  VARCHAR(200)       NULL,
    APPVERSION               VARCHAR(200)       NULL,
    STATUS                   VARCHAR(200)       NULL,
    TESTCASEDETAIL           TEXT               NULL,
    CREATETIME               TIMESTAMP          NULL,
    ENDTIME                  TIMESTAMP          NULL,
    PROVIDERID               VARCHAR(200)       NULL,
    PACKAGEPATH              VARCHAR(200)       NULL,
    USERID                   VARCHAR(200)       NULL,
    USERNAME                 VARCHAR(200)       NULL,
    CONSTRAINT task_table_pkey PRIMARY KEY (ID)
);

DROP TABLE IF EXISTS TEST_CASE_TABLE;

CREATE TABLE TEST_CASE_TABLE (
    ID                       VARCHAR(200)       NOT NULL,
    NAMECH                   VARCHAR(200)       NULL,
    NAMEEN                   VARCHAR(200)       NULL,
    TYPE                     VARCHAR(200)       NULL,
    CLASSNAME                VARCHAR(200)       NULL,
    HASHCODE                 TEXT               NULL,
    DESCRIPTIONCH            TEXT               NULL,
    DESCRIPTIONEN            TEXT               NULL,
    FILEPATH                 VARCHAR(200)       NULL,
    CODELANGUAGE             VARCHAR(200)       NULL,
    EXPECTRESULTCH           VARCHAR(200)       NULL,
    EXPECTRESULTEN           VARCHAR(200)       NULL,
    TESTSUITEIDLIST          TEXT               NULL,
    TESTSTEPCH               TEXT               NULL,
    TESTSTEPEN               TEXT               NULL,
    CONSTRAINT test_case_table_pkey PRIMARY KEY (ID)
);

DROP TABLE IF EXISTS TEST_SCENARIO_TABLE;

CREATE TABLE TEST_SCENARIO_TABLE (
    ID                       VARCHAR(200)       NOT NULL,
    NAMECH                   VARCHAR(200)       NULL,
    NAMEEN                   VARCHAR(200)       NULL,
    DESCRIPTIONCh            TEXT               NULL,
    DESCRIPTIONEN            TEXT               NULL,
    LABEL                    VARCHAR(200)       NULL,
    CONSTRAINT test_scenario_table_pkey PRIMARY KEY (ID)
);

DROP TABLE IF EXISTS TEST_SUITE_TABLE;

CREATE TABLE TEST_SUITE_TABLE (
    ID                       VARCHAR(200)       NOT NULL,
    NAMECH                   VARCHAR(200)       NULL,
    NAMEEN                   VARCHAR(200)       NULL,
    DESCRIPTIONCh            TEXT               NULL,
    DESCRIPTIONEN            TEXT               NULL,
    SCENARIOIDLIST           VARCHAR(255)       NULL,
    CONSTRAINT test_suite_table_pkey PRIMARY KEY (ID)
);

DROP TABLE IF EXISTS FILE_TABLE;

CREATE TABLE FILE_TABLE (
    FILEID                   VARCHAR(200)       NOT NULL,
    TYPE                     VARCHAR(200)       NOT NULL,
    CREATETIME               TIMESTAMP          NULL,
    FILEPATH                 VARCHAR(200)       NULL
);
alter table FILE_TABLE add constraint file_table_pkey unique(FILEID,TYPE);

DROP TABLE IF EXISTS CONTRIBUTION_TABLE;

CREATE TABLE CONTRIBUTION_TABLE (
    ID                       VARCHAR(200)       NOT NULL,
    NAME                     VARCHAR(200)       NULL,
    OBJECTIVE                VARCHAR(200)       NULL,
    STEP                     TEXT               NULL,
    EXPECTRESULT             TEXT               NULL,
    TYPE                     VARCHAR(255)       NULL,
    CREATETIME               TIMESTAMP          NULL,
    FILEPATH                 VARCHAR(200)       NULL,
    CONSTRAINT contribution_table_pkey PRIMARY KEY (ID)
);

INSERT INTO public.test_scenario_table(
  id, nameCh,nameEn, descriptionCh,descriptionEn,label)
  VALUES ('4d203111-1111-4f62-aabb-8ebcec357f87','社区场景','EdgeGallery Community Scenario','适用于社区场景的测试','suite for EdgeGallery community test','EdgeGallery'),
  ('e71718a5-864a-49e5-855a-5805a5e9f97d','中国联通','China Unicom Scenario','适用于中国联通场景的测试','suite for China Unicom test','China Unicom'),
  ('6fe8581c-b83f-40c2-8f5b-505478f9e30b','中国移动','China Mobile Scenario','适用于中国移动场景的测试','suite for China Mobile test','China Mobile'),
  ('96a82e85-d40d-4ce5-beec-2dd1c9a3d41d','中国电信','China Telecom Scenario','适用于中国电信场景的测试','suite for China Telecom test','China Telecom');

INSERT INTO public.test_suite_table(
  id, nameCh,nameEn, descriptionCh,descriptionEn,scenarioIdList)
  VALUES ('522684bd-d6df-4b47-aab8-b43f1b4c19c0','遵从性测试','Compliance Test','遵从社区APPD标准、ETSI标准对应用包结构进行校验','Validate app package structure according to commnunity and ETSI standard','4d203111-1111-4f62-aabb-8ebcec357f87'),
  ('6d04da1b-1f36-4295-920a-8074f7f9d942','沙箱测试','Sandbox Test','应用包部署测试','App package deployment test','4d203111-1111-4f62-aabb-8ebcec357f87'),
  ('743abd93-57a3-499d-9591-fa7db86a4778','安全性测试','Security Test','应用包安全测试','App package security test','4d203111-1111-4f62-aabb-8ebcec357f87'),
  ('111684bd-d6df-4b47-aab8-b43f1b4c19c0','中国移动遵从性测试','China Mobile Compliance Test','遵从中国移动标准对应用包结构进行校验','Validate app package structure according to China Mobile standard','6fe8581c-b83f-40c2-8f5b-505478f9e30b'),
  ('1114da1b-1f36-4295-920a-8074f7f9d942','中国移动沙箱测试','China Mobile Sandbox Test','应用包部署测试中国移动版','App package deployment test China Mobile version','6fe8581c-b83f-40c2-8f5b-505478f9e30b'),
  ('222684bd-d6df-4b47-aab8-b43f1b4c19c0','中国联通遵从性测试','China Unicom Compliance Test','遵从中国联通标准对应用包结构进行校验','Validate app package structure according to China Unicom standard','e71718a5-864a-49e5-855a-5805a5e9f97d'),
  ('2224da1b-1f36-4295-920a-8074f7f9d942','中国联通沙箱测试','China Unicom Sandbox Test','应用包部署测试中国联通版','App package deployment test China Unicom version','e71718a5-864a-49e5-855a-5805a5e9f97d'),
  ('333684bd-d6df-4b47-aab8-b43f1b4c19c0','中国电信遵从性测试','China Telecom Compliance Test','遵从中国电信标准对应用包结构进行校验','Validate app package structure according to China Telecom standard','96a82e85-d40d-4ce5-beec-2dd1c9a3d41d'),
  ('3334da1b-1f36-4295-920a-8074f7f9d942','中国电信沙箱测试','China Telecom Sandbox Test','应用包部署测试中国电信版','App package deployment test China Telecom version','96a82e85-d40d-4ce5-beec-2dd1c9a3d41d');

 INSERT INTO public.test_case_table(
  id, nameCh,nameEn, hashCode,type, classname,  descriptionCh,descriptionEn,filePath,codeLanguage,expectResultCh,expectResultEn,testStepCh,testStepEn,testSuiteIdList)
  VALUES ('4d203173-1111-4f62-aabb-8ebcec357f87','MF文件路径校验','Manifest File Path Validation','','automatic','SuffixTestCaseInner','根目录必须包含以.mf结尾的文件','Root path must contain the file which name ends of .mf','','java','根目录存在以.mf结尾的文件','there has .mf file in root path.','1.打开csar包 2.检查根目录存在以.mf结尾的文件','1.open csar package 2.there has .mf file in root path','522684bd-d6df-4b47-aab8-b43f1b4c19c0,111684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-2222-4f62-aabb-8ebcec357f87','MF文件必填字段校验','Manifest File Field Validation','','automatic','MFContentTestCaseInner','.mf文件必须包含如下字段： app_product_name, app_provider_id, app_package_version, app_release_date_time, app_class and app_package_description','.mf file must contain the following field: app_product_name, app_provider_id, app_package_version, app_release_date_time, app_class and app_package_description','','java','必填字段都存在','the requirement fileds must exist.','1.打开csar包 2.打开.mf文件 3.校验必填字段是否都存在','1.open csar package 2.open .mf file 3.validate the requirement fields exist','522684bd-d6df-4b47-aab8-b43f1b4c19c0,222684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-3333-4f62-aabb-8ebcec357f87','MF文件Source路径校验','Manifest File Source Path Validation','','automatic','SourcePathTestCaseInner','Source字段的值必须是正确的文件路径，文件必须存在','The value of Source filed must be right path, the corresponding file must exist','','java','Source字段的值必须是正确的路径，路径中的文件必须存在','the value of source must right path.','1.打开csar包 2.打开.mf文件 3.查看Source字段的值对应的文件路径是否存在','1.open csar package 2.open .mf file 3.validate the value of source must right path','522684bd-d6df-4b47-aab8-b43f1b4c19c0,222684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-4444-4f62-aabb-8ebcec357f87','TOSCA文件校验','Tosca File Validation','','automatic','TOSCAFileTestCaseInner','TOSCA.meta文件必须存在，该文件必须包含字段Entry-Definitions，且其值对应的路径必须是正确的路径，路径中的文件必须存在','ToscaFileValidation  TOSCA.meta file must exist, and it must contain the field: Entry-Definitions, and the the value of the filed must be right path, the corresponding file must exist','','java','tosca文件存在，且必填字段及内容正确','tosca file exists and field is right.','1.打开csar包 2.校验TOSCA.meta文件是否存在 3.校验必填字段是否存在 4.校验字段Entry-Definitions对应的值路径正确性','1.open csar package 2.validate the existence of TOSCA.meta file 3.validate the requirement field 4.validate the value of Entry-Definitions field','522684bd-d6df-4b47-aab8-b43f1b4c19c0,333684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-5555-4f62-aabb-8ebcec357f87','应用实例化','Application Instantiation','','automatic','InstantiateAppTestCaseInner','将应用包部署到边缘节点','Instantiate application and its dependency application on one edge host','','jar','应用包可以成功部署','app can instantiate successfully.','部署应用包到对应的边缘节点','Deploy application package to edge node','6d04da1b-1f36-4295-920a-8074f7f9d942'),
  ('4d203173-6666-4f62-aabb-8ebcec357f87','应用实例化终止','Application Termination','','automatic','UninstantiateAppTestCaseInner','将实例化后的应用包卸载','Uninstantiate application and its dependency application on one edge host','','jar','实例化后的应用包成功卸载','app can uninstantiate successfully.','卸载实例化后的应用','Terminate the application instance','6d04da1b-1f36-4295-920a-8074f7f9d942'),
  ('4d203173-7777-4f62-aabb-8ebcec357f87','病毒扫描','Virus Scanning','','automatic','VirusScanTestCaseInner','对应用包进行病毒扫描','scan application package virus','','java','应用包中未扫描出病毒','app has no virus.','1.启动病毒扫描三方件 2.扫描应用包','1.start third-party software 2.scan application package','743abd93-57a3-499d-9591-fa7db86a4778'),
  ('4d203173-8888-4f62-aabb-8ebcec357f87','防炸弹攻击','Bomb Defense','','automatic','BombDefenseTestCase','对应用包进行防炸弹攻击校验','bomb defense','','jar','应用包具有防炸弹攻击能力','no bomb defense.','1.校验文件大小不大于50MB 2.解压后的文件大小不大于100MB 3.文件数量不大于1024个','1.file size can not exceeding 50MB 2.uncompress file can not exceeding 100MB 3.the number of file can not exceeding 1024','743abd93-57a3-499d-9591-fa7db86a4778'),
  ('4d203173-9999-4f62-aabb-8ebcec357f87','APPD文件目录校验','APPD File Dir Validation','','automatic','APPDValidation','根目录下必须包含APPD文件目录','Root directory must contain APPD file dir','','java','根目录下存在APPD文件目录','Root directory contains APPD file dir','1.打开csar包 2.校验根目录下存在APPD目录','1.open csar package 2.validate root directory contains APPD directory','522684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-1000-4f62-aabb-8ebcec357f87','Artifacts文件目录校验','Artifacts File Dir Validation','','automatic','ArtifactsValidation','根目录下必须包含Artifacts文件目录','Root directory must contain Artifacts file dir','','java','根目录下存在Artifacts文件目录','Root directory contains Artifacts file dir','1.打开csar包 2.校验根目录下存在Artifacts目录','1.open csar package 2.validate root directory contains Artifacts directory','522684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-1001-4f62-aabb-8ebcec357f87','TOSCA-Metadata文件目录校验','Tosca Metadata File Dir Validation','','automatic','ToscaMetadataValidation','根目录下必须包含TOSCA-Metadata文件目录','Root directory must contain TOSCA-Metadata file dir','','java','根目录下存在TOSCA-Metadata文件目录','Root directory contains TOSCA-Metadata file dir','1.打开csar包 2.校验根目录下存在TOSCA-Metadata目录','1.open csar package 2.validate root directory contains TOSCA-Metadata directory','522684bd-d6df-4b47-aab8-b43f1b4c19c0,111684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-1002-4f62-aabb-8ebcec357f87','yaml描述文件校验','Yaml Description File Validation','','automatic','YamlDescriptionFileValidation','APPD/Definition/目录下必须存在yaml描述文件','There must contain yaml file in APPD/Definition/ dir','','java','APPD/Definition/目录下包含yaml描述文件','APPD/Definition/ dir contains yaml file','1.打开csar包 2.校验APPD/Definition/目录下包含yaml描述文件','1.open csar package 2.validate APPD/Definition/ dir contains yaml file','522684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-1003-4f62-aabb-8ebcec357f87','mf文件hash值列表校验','Manifest File Hash List Validation','','automatic','ManifestFileHashListValidation','.mf文件中，每个文件必须有对应的hash值描述','Every Source file must has Hash field in manifest file','','java','.mf文件中每个文件都有对应的hash值描述','Every Source file has Hash field in manifest file','1.打开csar包 2.打开.mf文件 3.校验每个Source字段对应的文件都有Hash字段的描述','1.open csar package 2.open .mf file 3.validate every Source file has Hash field in manifest file','743abd93-57a3-499d-9591-fa7db86a4778'),
  ('4d203173-1004-4f62-aabb-8ebcec357f87','CPU数量描述字段校验','CPU Number Description Validation','','automatic','CPUNumberDescriptionValidation','yaml描述文件中必须有对cpu数量的描述字段：num_virtual_cpu','There must contain cpu number description in yaml file','','java','yaml描述文件中包含对cpu数量的描述','There contains cpu number description in yaml file','1.打开csar包 2.打开yaml描述文件 3.校验有num_virtual_cpu字段','1.open csar package 2.open yaml description file 3.validate existence of num_virtual_cpu field','522684bd-d6df-4b47-aab8-b43f1b4c19c0,111684bd-d6df-4b47-aab8-b43f1b4c19c0'),
  ('4d203173-1005-4f62-aabb-8ebcec357f87','虚拟内存描述字段校验','Virtual Memory Description Validation','','automatic','VirtualMemoryDescriptionValidation','yaml文件中有对虚拟内存大小的描述字段：virtual_mem_size','There must contain virtual memory size description in yaml file','','java','yaml描述文件中包含对虚拟内存大小的描述','There contains virtual memory size description in yaml file','1.打开csar包 2.打开yaml描述文件 3.校验有virtual_mem_size字段','1.open csar package 2.open yaml description file 3.validate existence of virtual_mem_size','522684bd-d6df-4b47-aab8-b43f1b4c19c0,333684bd-d6df-4b47-aab8-b43f1b4c19c0');
