create or replace package sample_pkg is
    --
    -- Error Handling function
    --
    function demo_error_handling (
        p_error in apex_error.t_error )
        return apex_error.t_error_result;
    
    --
    -- Tag Cleaner function
    --
    function demo_tags_cleaner (
        p_tags  in varchar2,
        p_case  in varchar2 default 'U') 
        return varchar2;
    
    --
    -- Tag Synchronisation Procedure
    --
    procedure demo_tag_sync (
        p_new_tags          in varchar2,
        p_old_tags          in varchar2,
        p_content_type      in varchar2,
        p_content_id        in number );

end sample_pkg;
/

create sequence DEMO_CUST_SEQ start with 100;
create sequence DEMO_ORD_SEQ start with 100;
create sequence DEMO_PROD_SEQ start with 100;
create sequence DEMO_ORDER_ITEMS_SEQ start with 100;

-- Table: DEMO_TAGS
CREATE TABLE demo_tags (
    id                      number primary key,
    tag                     varchar2(255) not null,
    content_id              number,
    content_type            varchar2(30)
                            constraint demo_tags_ck check
                            (content_type in ('CUSTOMER','ORDER','PRODUCT')),
    --
    created                 timestamp with local time zone,
    created_by              varchar2(255),
    updated                 timestamp with local time zone,
    updated_by              varchar2(255)
);


create or replace trigger demo_tags_biu
   before insert or update on demo_tags
   for each row
   begin
      if inserting then
         if :NEW.ID is null then
           select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
           into :new.id
           from dual;
         end if;
         :NEW.CREATED := localtimestamp;
         :NEW.CREATED_BY := nvl(v('APP_USER'),USER);
      end if;

      if updating then
         :NEW.UPDATED := localtimestamp;
         :NEW.UPDATED_BY := nvl(v('APP_USER'),USER);
      end if;
end;
/
    
-- Table: DEMO_TAGS_TYPE_SUM
create table demo_tags_type_sum (
    tag                             varchar2(255),
    content_type                    varchar2(30),
    tag_count                       number,
    constraint demo_tags_type_sum_pk primary key (tag,content_type)
);
    

-- Table: DEMO_TAGS_SUM
create table demo_tags_sum (
    tag                             varchar2(255),
    tag_count                       number,
    constraint demo_tags_sum_pk primary key (tag)
);

-- Table: DEMO_CUSTOMERS
CREATE TABLE  "DEMO_CUSTOMERS" (    
    "CUSTOMER_ID"          NUMBER       NOT NULL ENABLE,
    "CUST_FIRST_NAME"      VARCHAR2(20) NOT NULL ENABLE,
    "CUST_LAST_NAME"       VARCHAR2(20) NOT NULL ENABLE,
    "CUST_STREET_ADDRESS1" VARCHAR2(60),
    "CUST_STREET_ADDRESS2" VARCHAR2(60),
    "CUST_CITY"            VARCHAR2(30),
    "CUST_STATE"           VARCHAR2(2),
    "CUST_POSTAL_CODE"     VARCHAR2(10),
    "CUST_EMAIL"           VARCHAR2(30),
    "PHONE_NUMBER1"        VARCHAR2(25),
    "PHONE_NUMBER2"        VARCHAR2(25),
    "URL"                  VARCHAR2(100),
    "CREDIT_LIMIT"         NUMBER(9,2),
    "TAGS"                 VARCHAR2(4000),
    CONSTRAINT "DEMO_CUST_CREDIT_LIMIT_MAX" CHECK (credit_limit <= 5000) ENABLE,
    CONSTRAINT "DEMO_CUSTOMERS_PK" PRIMARY KEY ("CUSTOMER_ID") ENABLE,
    CONSTRAINT "DEMO_CUSTOMERS_UK" UNIQUE ("CUST_FIRST_NAME","CUST_LAST_NAME")
 );
CREATE INDEX  "DEMO_CUST_NAME_IX" ON  "DEMO_CUSTOMERS" ("CUST_LAST_NAME", "CUST_FIRST_NAME");

CREATE OR REPLACE TRIGGER  "DEMO_CUSTOMERS_BIU"
  before insert or update ON demo_customers FOR EACH ROW
DECLARE
  cust_id number;
BEGIN
  if inserting then  
    if :new.customer_id is null then
      select demo_cust_seq.nextval
        into cust_id
        from dual;
      :new.customer_id := cust_id;
    end if;
    if :new.tags is not null then
          :new.tags := sample_pkg.demo_tags_cleaner(:new.tags);
    end if;
  end if;

  sample_pkg.demo_tag_sync(
     p_new_tags      => :new.tags,
     p_old_tags      => :old.tags,
     p_content_type  => 'CUSTOMER',
     p_content_id    => :new.customer_id );
END;
/

create or replace trigger "DEMO_CUSTOMERS_BD"
    before delete on demo_customers
    for each row
begin
    sample_pkg.demo_tag_sync(
        p_new_tags      => null,
        p_old_tags      => :old.tags,
        p_content_type  => 'CUSTOMER',
        p_content_id    => :old.customer_id );

end;
/

-- Table: DEMO_ORDERS
CREATE TABLE  "DEMO_ORDERS" (    
    "ORDER_ID"           NUMBER NOT NULL ENABLE,
    "CUSTOMER_ID"        NUMBER NOT NULL ENABLE,
    "ORDER_TOTAL"        NUMBER(8,2),
    "ORDER_TIMESTAMP"    TIMESTAMP with local time zone,
    "USER_NAME"          VARCHAR2(100),
    "TAGS"               VARCHAR2(4000),
    CONSTRAINT "DEMO_ORDER_TOTAL_MIN" CHECK (order_total >= 0) ENABLE,
    CONSTRAINT "DEMO_ORDER_PK" PRIMARY KEY ("ORDER_ID") ENABLE,
    CONSTRAINT "DEMO_ORDERS_CUSTOMER_ID_FK" FOREIGN KEY ("CUSTOMER_ID")
    REFERENCES  "DEMO_CUSTOMERS" ("CUSTOMER_ID") ON DELETE CASCADE ENABLE
);
CREATE INDEX  "DEMO_ORD_CUSTOMER_IX" ON  "DEMO_ORDERS" ("CUSTOMER_ID");

CREATE OR REPLACE TRIGGER  "DEMO_ORDERS_BIU"
  before insert or update ON demo_orders FOR EACH ROW
DECLARE
  order_id number;
BEGIN
  if inserting then  
    if :new.order_id is null then
      select demo_ord_seq.nextval
        INTO order_id
        FROM dual;
      :new.order_id := order_id;
    end if;
    if :new.tags is not null then
       :new.tags := sample_pkg.demo_tags_cleaner(:new.tags);
    end if;
  end if;
  
  sample_pkg.demo_tag_sync(
    p_new_tags      => :new.tags,
    p_old_tags      => :old.tags,
    p_content_type  => 'ORDER',
    p_content_id    => :new.order_id );
END;
/

create or replace trigger "DEMO_ORDERS_BD"
    before delete on demo_orders
    for each row
begin
    sample_pkg.demo_tag_sync(
        p_new_tags      => null,
        p_old_tags      => :old.tags,
        p_content_type  => 'ORDER',
        p_content_id    => :old.order_id );

end;
/


-- Table: DEMO_PRODUCT_INFO
CREATE TABLE  "DEMO_PRODUCT_INFO" (    
    "PRODUCT_ID"          NUMBER NOT NULL ENABLE,
    "PRODUCT_NAME"        VARCHAR2(50),
    "PRODUCT_DESCRIPTION" VARCHAR2(2000),
    "CATEGORY"            VARCHAR2(30),
    "PRODUCT_AVAIL"       VARCHAR2(1),
    "LIST_PRICE"          NUMBER(8,2),
    "PRODUCT_IMAGE"       BLOB,
    "MIMETYPE"            VARCHAR2(255),
    "FILENAME"            VARCHAR2(400),
    "IMAGE_LAST_UPDATE"   TIMESTAMP with local time zone,
    "TAGS"                VARCHAR2(4000),
    CONSTRAINT "DEMO_PRODUCT_INFO_PK" primary key ("PRODUCT_ID") ENABLE,
    CONSTRAINT "DEMO_PRODUCT_INFO_UK" unique ("PRODUCT_NAME") ENABLE
);

CREATE OR REPLACE TRIGGER  "DEMO_PRODUCT_INFO_BIU"
  before insert or update ON demo_product_info FOR EACH ROW
DECLARE
  prod_id number;
BEGIN
  if inserting then  
    if :new.product_id is null then
      select demo_prod_seq.nextval
        into prod_id
        from dual;
      :new.product_id := prod_id;
    end if;
    if :new.tags is not null then
          :new.tags := sample_pkg.demo_tags_cleaner(:new.tags);
    end if;
  end if;

  sample_pkg.demo_tag_sync(
    p_new_tags      => :new.tags,
    p_old_tags      => :old.tags,
    p_content_type  => 'PRODUCT',
    p_content_id    => :new.product_id );
END;
/

create or replace trigger "DEMO_PRODUCT_INFO_BD"
    before delete on demo_product_info
    for each row
begin
    sample_pkg.demo_tag_sync(
        p_new_tags      => null,
        p_old_tags      => :old.tags,
        p_content_type  => 'PRODUCT',
        p_content_id    => :old.product_id );

end;
/


-- Table:  DEMO_ORDER_ITEMS
CREATE TABLE  "DEMO_ORDER_ITEMS" (
    "ORDER_ITEM_ID" NUMBER(3,0) NOT NULL ENABLE,
    "ORDER_ID" NUMBER NOT NULL ENABLE,
    "PRODUCT_ID" NUMBER NOT NULL ENABLE,
    "UNIT_PRICE" NUMBER(8,2) NOT NULL ENABLE,
    "QUANTITY" NUMBER(8,0) NOT NULL ENABLE,
    CONSTRAINT "DEMO_ORDER_ITEMS_PK" PRIMARY KEY ("ORDER_ITEM_ID") ENABLE,
    CONSTRAINT "DEMO_ORDER_ITEMS_UK" UNIQUE ("ORDER_ID","PRODUCT_ID") ENABLE,
    CONSTRAINT "DEMO_ORDER_ITEMS_FK" FOREIGN KEY ("ORDER_ID")
     REFERENCES  "DEMO_ORDERS" ("ORDER_ID") ON DELETE CASCADE ENABLE,
    CONSTRAINT "DEMO_ORDER_ITEMS_PRODUCT_ID_FK" FOREIGN KEY ("PRODUCT_ID")
     REFERENCES  "DEMO_PRODUCT_INFO" ("PRODUCT_ID") ON DELETE CASCADE ENABLE
);

CREATE OR REPLACE TRIGGER  "DEMO_ORDER_ITEMS_BI"
  BEFORE insert on "DEMO_ORDER_ITEMS" for each row
declare
  order_item_id number;
begin
  if :new.order_item_id is null then
    select demo_order_items_seq.nextval 
      into order_item_id 
      from dual;
    :new.order_item_id := order_item_id;
  end if;
end;
/

CREATE OR REPLACE TRIGGER  "DEMO_ORDER_ITEMS_AIUD_TOTAL"
  after insert or update or delete on demo_order_items
begin
  -- Update the Order Total when any order item is changed
  update demo_orders set order_total =
  (select sum(unit_price*quantity) from demo_order_items
    where demo_order_items.order_id = demo_orders.order_id);
end;
/

CREATE OR REPLACE TRIGGER  "DEMO_ORDER_ITEMS_BIU_GET_PRICE"
  before insert or update on demo_order_items for each row
declare
  l_list_price number;
begin
  if :new.unit_price is null then
    -- First, we need to get the current list price of the order line item
    select list_price
    into l_list_price
    from demo_product_info
    where product_id = :new.product_id;
    -- Once we have the correct price, we will update the order line with the correct price
    :new.unit_price := l_list_price;
  end if;
end;
/


-- Table: DEMO_STATES
CREATE TABLE  "DEMO_STATES" (
    "ST" VARCHAR2(30),
    "STATE_NAME" VARCHAR2(30)
 );

-- Table: DEMO_CONSTRAINT_LOOKUP
create table DEMO_CONSTRAINT_LOOKUP
(
  CONSTRAINT_NAME VARCHAR2(30)   primary key,
  MESSAGE         VARCHAR2(4000) not null
);

create or replace package body sample_pkg as
    --
    -- Error Handling function
    --
    function demo_error_handling (
        p_error in apex_error.t_error )
        return apex_error.t_error_result
    is
        l_result          apex_error.t_error_result;
        l_reference_id    number;
        l_constraint_name varchar2(255);
    begin
        l_result := apex_error.init_error_result (
                        p_error => p_error );

        -- If it's an internal error raised by APEX, like an invalid statement or
        -- code which can't be executed, the error text might contain security sensitive
        -- information. To avoid this security problem we can rewrite the error to
        -- a generic error message and log the original error message for further
        -- investigation by the help desk.
        if p_error.is_internal_error then
            -- mask all errors that are not common runtime errors (Access Denied
            -- errors raised by application / page authorization and all errors
            -- regarding session and session state)
            if not p_error.is_common_runtime_error then
                -- log error for example with an autonomous transaction and return
                -- l_reference_id as reference#
                -- l_reference_id := log_error (
                --                       p_error => p_error );
                --
    
                -- Change the message to the generic error message which doesn't expose
                -- any sensitive information.
                l_result.message         := 'An unexpected internal application error has occurred. '||
                                            'Please get in contact with your system administrator and provide '||
                                            'reference# '||to_char(l_reference_id, '999G999G999G990')||
                                            ' for further investigation.';
                l_result.additional_info := null;
            end if;
        else
            -- Always show the error as inline error
            -- Note: If you have created manual tabular forms (using the package
            --       apex_item/htmldb_item in the SQL statement) you should still
            --       use "On error page" on that pages to avoid loosing entered data
            l_result.display_location := case
                                           when l_result.display_location = apex_error.c_on_error_page then apex_error.c_inline_in_notification
                                           else l_result.display_location
                                         end;
    
            -- If it's a constraint violation like
            --
            --   -) ORA-00001: unique constraint violated
            --   -) ORA-02091: transaction rolled back (-> can hide a deferred constraint)
            --   -) ORA-02290: check constraint violated
            --   -) ORA-02291: integrity constraint violated - parent key not found
            --   -) ORA-02292: integrity constraint violated - child record found
            --
            -- we try to get a friendly error message from our constraint lookup configuration.
            -- If we don't find the constraint in our lookup table we fallback to
            -- the original ORA error message.
            if p_error.ora_sqlcode in (-1, -2091, -2290, -2291, -2292) then
                l_constraint_name := apex_error.extract_constraint_name (
                                         p_error => p_error );

                begin
                    select message
                      into l_result.message
                      from demo_constraint_lookup
                     where constraint_name = l_constraint_name;
                exception when no_data_found then null; -- not every constraint has to be in our lookup table
                end;
            end if;

            -- If an ORA error has been raised, for example a raise_application_error(-20xxx, '...')
                -- in a table trigger or in a PL/SQL package called by a process and we
            -- haven't found the error in our lookup table, then we just want to see
            -- the actual error text and not the full error stack with all the ORA error numbers.
            if p_error.ora_sqlcode is not null and l_result.message = p_error.message then
                l_result.message := apex_error.get_first_ora_error_text (
                                        p_error => p_error );
            end if;

            -- If no associated page item/tabular form column has been set, we can use
            -- apex_error.auto_set_associated_item to automatically guess the affected
            -- error field by examine the ORA error for constraint names or column names.
            if l_result.page_item_name is null and l_result.column_alias is null then
                apex_error.auto_set_associated_item (
                    p_error        => p_error,
                    p_error_result => l_result );
            end if;
        end if;

        return l_result;
    end demo_error_handling;
        
    
    ---
    --- Tag Cleaner function
    ---
    function demo_tags_cleaner (
        p_tags  in varchar2,
        p_case  in varchar2 default 'U' ) return varchar2
    is
        type tags is table of varchar2(255) index by varchar2(255);
        l_tags_a        tags;
        l_tag           varchar2(255);
        l_tags          apex_application_global.vc_arr2;
        l_tags_string   varchar2(32767);
        i               integer;
    begin

        l_tags := apex_util.string_to_table(p_tags,',');

        for i in 1..l_tags.count loop
            --remove all whitespace, including tabs, spaces, line feeds and carraige returns with a single space
            l_tag := substr(trim(regexp_replace(l_tags(i),'[[:space:]]{1,}',' ')),1,255);
  
            if l_tag is not null and l_tag != ' ' then
                if p_case = 'U' then
                    l_tag := upper(l_tag);
                elsif p_case = 'L' then
                    l_tag := lower(l_tag);
                end if;
                --add it to the associative array, if it is a duplicate, it will just be replaced
                l_tags_a(l_tag) := l_tag;
            end if;
        end loop;

        l_tag := null;

        l_tag := l_tags_a.first;

        while l_tag is not null loop
            l_tags_string := l_tags_string||l_tag;
            if l_tag != l_tags_a.last then
                l_tags_string := l_tags_string||', ';
            end if;
            l_tag := l_tags_a.next(l_tag);
        end loop;

        return substr(l_tags_string,1,4000);

    end demo_tags_cleaner;

    ---
    --- Tag Synchronisation Procedure
    ---
    procedure demo_tag_sync (
        p_new_tags          in varchar2,
        p_old_tags          in varchar2,
        p_content_type      in varchar2,
        p_content_id        in number )
    as
        type tags is table of varchar2(255) index by varchar2(255);
        l_new_tags_a    tags;
        l_old_tags_a    tags;
        l_new_tags      apex_application_global.vc_arr2;
        l_old_tags      apex_application_global.vc_arr2;
        l_merge_tags    apex_application_global.vc_arr2;
        l_dummy_tag     varchar2(255);
        i               integer;
    begin

        l_old_tags := apex_util.string_to_table(p_old_tags,', ');
        l_new_tags := apex_util.string_to_table(p_new_tags,', ');

        if l_old_tags.count > 0 then --do inserts and deletes

            --build the associative arrays
            for i in 1..l_old_tags.count loop
                l_old_tags_a(l_old_tags(i)) := l_old_tags(i);
            end loop;

            for i in 1..l_new_tags.count loop
                l_new_tags_a(l_new_tags(i)) := l_new_tags(i);
            end loop;

            --do the inserts
            for i in 1..l_new_tags.count loop
                begin
                    l_dummy_tag := l_old_tags_a(l_new_tags(i));
                exception when no_data_found then
                    insert into demo_tags (tag, content_id, content_type )
                        values (l_new_tags(i), p_content_id, p_content_type );
                    l_merge_tags(l_merge_tags.count + 1) := l_new_tags(i);
                end;
            end loop;

            --do the deletes
            for i in 1..l_old_tags.count loop
                begin
                    l_dummy_tag := l_new_tags_a(l_old_tags(i));
                exception when no_data_found then
                    delete from demo_tags where content_id = p_content_id and tag = l_old_tags(i);
                    l_merge_tags(l_merge_tags.count + 1) := l_old_tags(i);
                end;
            end loop;
        else --just do inserts
            for i in 1..l_new_tags.count loop
                insert into demo_tags (tag, content_id, content_type )
                    values (l_new_tags(i), p_content_id, p_content_type );
                l_merge_tags(l_merge_tags.count + 1) := l_new_tags(i);
            end loop;
        end if;

        for i in 1..l_merge_tags.count loop
            merge into demo_tags_type_sum s
            using (select count(*) tag_count
                     from demo_tags
                    where tag = l_merge_tags(i) and content_type = p_content_type ) t
               on (s.tag = l_merge_tags(i) and s.content_type = p_content_type )
             when not matched then insert (tag, content_type, tag_count)
                                   values (l_merge_tags(i), p_content_type, t.tag_count)
             when matched then update set s.tag_count = t.tag_count;

            merge into demo_tags_sum s
            using (select sum(tag_count) tag_count
                     from demo_tags_type_sum
                    where tag = l_merge_tags(i) ) t
               on (s.tag = l_merge_tags(i) )
             when not matched then insert (tag, tag_count)
                                   values (l_merge_tags(i), t.tag_count)
             when matched then update set s.tag_count = t.tag_count;
        end loop;

    end demo_tag_sync;


end sample_pkg;
/

create or replace package sample_data_pkg as

  function varchar2_to_blob(p_varchar2_tab in dbms_sql.varchar2_table) return blob;
  procedure delete_data;
  procedure insert_data;

end sample_data_pkg;
/
show errors

create or replace package body sample_data_pkg as

function varchar2_to_blob(p_varchar2_tab in dbms_sql.varchar2_table)
    return blob
is
  l_blob blob;
  l_raw  raw(500);
  l_size number;
begin
  dbms_lob.createtemporary(l_blob, true, dbms_lob.session);
  for i in 1 .. p_varchar2_tab.count loop
    l_size := length(p_varchar2_tab(i)) / 2;
    dbms_lob.writeappend(l_blob, l_size, hextoraw(p_varchar2_tab(i)));
  end loop;
  return l_blob;
exception
  when others then
    dbms_lob.close(l_blob);
end varchar2_to_blob;  

procedure delete_data is
begin
  delete demo_product_info where product_id <= 10;
  delete demo_customers where customer_id <= 10;
  delete demo_states;
  delete demo_constraint_lookup where constraint_name in ('DEMO_CUST_CREDIT_LIMIT_MAX','DEMO_CUSTOMERS_UK','DEMO_PRODUCT_INFO_UK','DEMO_ORDER_ITEMS_UK');
end delete_data;

procedure insert_data is
  i           dbms_sql.varchar2_table;
  j           dbms_sql.varchar2_table default wwv_flow_api.empty_varchar2_table;
  l_blob      blob;
begin
  -- Table: DEMO_PRODUCT_INFO - Product 1
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB00840009060610100F120D12140F130F1210171510141410100F1410101410151614101414171B261E1719231912121F2F2023282C2C2C2C151F31353C2A35262B2C2901090A0A0D0A0D190C0E1A';
  i(2)  := '291E1C1829352929292934292C29292934302C3435292929292C3229292C2E30292C2A2929292929292A34342929292A362934293229FFC00011080068006803012200021101031101FFC4001B0000020301010100000000000000000000000502030401';
  i(3)  := '0706FFC400381000020102030406060A0300000000000000010203110412210531415161718191B1D113162252A1C10632627292A2B2E1F0F1144253FFC40014010100000000000000000000000000000000FFC400141101000000000000000000000000';
  i(4)  := '00000000FFDA000C03010002110311003F00F71000000038DD80CD8DDA54E8FD7767C12D5BEC17FAD14F8467F0425C52752ACE6EEEF2D38E9C2DD962FA7B39DAFBBAD80D7D6487B92EF45B4B6FD27BD4A3D6AFE026A5826DB5C8B6585CBBD3F15F003E96';
  i(5)  := '9D55259934D3E28909F62D55193A775AACCB5E4D2D3BFE0380000000000000000306D1C7BA6D452576AF77C3B05D3AB29272936F46D747616ED377AAD72497CFE6432E8D74018B0352DEC9B65BB4304A8B8BB9BE35565CCDA4B9B028A2E4E4D6693CBBD7';
  i(6)  := 'A3CA9DD70935AF6335CEAA8ACCC850C5427B9AEADCFAEDBCCB8F9DD018A9576EBA9BD13BAB2E09AD3E23AA1899C773D393D50A30D45B9C5F292F11C4D00D30D5B3C54B7735C9A2D316CD96928F4DFBFF00A368000000000009314AF526FED782488C5D8E';
  i(7)  := 'D4FAD2FBCFC59D4C0C98DC5C29ABCB7BDD15AB9752153C0E2312D395E953E09DD59756F6FA47F0A714DB495DEF7C7BC9E6E2025AFF0047249274E6EEB726EDF14729CEB474AD09597FB2D7BEDBC76AA0019B096D24ACD741A991549277B24FA34BF5F326';
  i(8)  := 'C0BF02ED3EB88C05D4349C7AFC50C4000000000004553EB4BEF3FD4C89D9BF6A4BED3FD4CED80132C488E43B18D80924EFC2D6D02DA9240076C409391C881645D9A7C9AF1198AA5B86917749F34074000008CE564DBDC95DF612336D0A96A72E9D3BC04C';
  i(9)  := '9712CBD8AA555477FF003F972553556E7A77BB0175395D26F7D89A2BB924C0929ABDB4BF207239955EFC4E30244A2884592B81218619DE11EAF016A66FC14BD8EA6FC6FF003034000000BF6C26E31D6DED6EB2D74180AB6CD4D631E86FBFFA0174AF75C5';
  i(10) := '5F57A69F02CBF1E9F995FA65C5A5DA5753190D1668DDB56575CC0D8892650EB1CFF200D2A471B323C747364E3FB5CB3D381A1324999957458AA202D36ECE96925D37EF5FB0BB31B366CBDA6B9AF07FB80C40000059B536142BC94DB926959DB5BAE1D0B8';
  i(11) := '80018BD49C33DF9DF6C57C8ED3FA13858C9497A44D3BA7996FEE000362D814FDEABF89791C7F47E973A9F897900010F56695F366AB7FBCBC89FABD4FDEABF8A3E47000EFABF0F7EA77C7C816C08FBF53F2F9000125B157FD2A7E5F22DC2ECEC92CD9E4F4';
  i(12) := 'DCD25E00006D00003FFFD9';
  l_blob := varchar2_to_blob(i);   
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(1, 'Business Shirt', 'Wrinkle-free cotton business shirt', 'Mens', 'Y', 50, l_blob,'image/jpeg','shirt.jpg',systimestamp,'Top seller');

  -- Table: DEMO_PRODUCT_INFO - Product 2
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB004300090607080706090807080A0A090B0D160F0D0C0C0D1B14151016201D2222201D1F1F2428342C242631271F1F2D3D2D3135373A3A3A232B3F443F384334393A37FFDB0043010A0A0A0D0C0D';
  i(2)  := '1A0F0F1A37251F253737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737FFC00011080068006803012200021101031101FFC4001C00010100020301010000000000000000000007';
  i(3)  := '01050406080203FFC4003D1000010303000507080807000000000000010002030405110607122141132231516171A123328191B1B2C1D11415174273A2C2E1083552626392F0FFC400160101010100000000000000000000000000000102FFC400161101';
  i(4)  := '010100000000000000000000000000000131FFDA000C03010002110311003F00B822220CAC2220D36995DA6B168B5CEE94DC919A969DD2462504B4BB8038238A81FDABE9954641B9450FE15247F1055135FF00719A9F4628A82225ACADAA025238B58368';
  i(5)  := '0FF6D9F528640730B2403EF7387664FCD54AED726B0F4B651CFD20ABC7F8E28DBEC62F96699E9387B2575EAE2F0241CD339009E9C1031B968E2635B308F1B8B3687FDE80BF6899B54F82778760F7E4223D4764B9C379B4D2DC69811154461E03BA47583D';
  i(6)  := 'C7217394E75275D24D63ADA17BB69B4B51B51E4EF0D78CE3D60FAD519468E288880888832B088832B0888239FC424DB42CB4CDE91CAC9E2C1F351DA3CF9685E31839C761562D7DC61D5D65706E5DC94C0F7658A3F2F92AB8DFD01C0B4FB5547323396C2F';
  i(7)  := 'FBCD3B2572E2DCF76EDC4839EA2B894FE71683CD3BD72C1C222A1A8E90FD3EF118E83144EF5177CD57148F519138D65E26079A2389847692E3F055C5161C5111144444044441958444126D7B47E52C737E3B3DC2A3978E646D9319C387B55B35EACCDBAC';
  i(8)  := 'F2637B6A9EDCF7B3F6516BC0CD13B72ACD628DD9D82B9A3A16AE85FE4D87B96CDDB813D43A0A0ADEA24E692F3BBA278C7E52AA6A5DA88C1B65DDE38D4B3DC55151A87144440444419584441958444130D7A39FF565A1A3CC354F27BC3377C546AB5BB701';
  i(9)  := '6F5E7D8AD3AF28F6ACD6C7EEE6D59DD9FEC2A31543C91559BAD4D01CD3E388385B57CC1A59B5E6BDBD5C56A2DC41E51B9FBCB6407290341192C38282CFA85FE4F750785537DC0AA2A57A8527EADBBB0F0A867BBFB2AA28D1C511101111011110111104E3';
  i(10) := '5DF1ED582DF2648D9ACC77E58EF928A551E663AD5AB5E240D1FB70E3F4E1EE3944EA5D81E8552EB596EA771A7AA9D993C94CC616F0E7079CFE55B2A576D31E47A5A46F053472865ABB1E90CF1F4518A79DDDA36DCD3E0E27D0BE58ED97646F0E6EF088B0';
  i(11) := '6A19F982F6D3B9DCAC2EC7616BBE4AAEA23A89AA2DD23B8D2ED1C4B461E476B1E07EB2ADCA35044E28808888088880888826FAF16E6C16E775568F71CA1F5AE3E66CEF20E30AE5AF1648746289EC692195AD2E3D5CC763C5445A4020CCE193D00AA9544D';
  i(12) := '5058C4FA15A5B34806DD631D4C3233B21B1923C5FE0A774F87C63686F6F4772B16A29CDAAD19BCC61C365D5EE6EEE039360524A8A47DBEE1514736E929DEE89DDED38F820EE1A9D70834F2368CE65A595BEC77E957D5E78D5538FDA1DBC0DFCD941EEE4D';
  i(13) := 'CBD0EA1044E288A222202222022220D6692D961D21B1D55AAA5EE8E3A86805ED0096E0820EFED0BA041A94B609335177AD7B3FA636319E3BD110774D12D11B5E89524F4F6A13113C9CA4AF9A4DA738E303A87829A6976ADB48AB748AB6BA823A49A0A99D';
  i(14) := 'F2B713ECB9A09CE08701E194441D87579AB67D86E02F177A80FAE667918A17E591ED3483B471CE3BFB876AA422202222022220FFD9';
  l_blob := varchar2_to_blob(i);
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(2, 'Trousers', 'Black trousers suitable for every business man', 'Mens', 'Y', 80, l_blob,'image/jpeg','pants.jpg',systimestamp,'Top seller');

  -- Table: DEMO_PRODUCT_INFO - Product 3
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB00840009060614120D1513131413131216141319111815111015121917131016191C151714181B281E23192F1F18141F302025332C2E2C2C151E3135312A35262B2D2B01090A0A0505050D05050D';
  i(2)  := '291812182929292929292929292929292929292929292929292929292929292929292929292929292929292929292929292929292929FFC00011080068006803012200021101031101FFC4001C0001000203010101000000000000000000000708030406';
  i(3)  := '050201FFC400351000010401010505060505010000000000010002031104210506071261223151819113144171A1C123324392B142647293A233FFC40014010100000000000000000000000000000000FFC4001411010000000000000000000000000000';
  i(4)  := '0000FFDA000C03010002110311003F009C511101111011110112D1011110111101111011110111783BF596E8B6564BD8E2C7888F2B81A20920687C7541A5BC9C4AC4C371612E9651A164601A3E0E71340F4D4F4514EF8F1632725CCF60E7E2B1A6F96391';
  i(5)  := 'DCCEB03F3BC575D171D24C4AD3BB76A83AB3BFF9FC95EF330EFD7DAB89A23AEB6BDFDC8E2BC98D23D99B24D910BAB90E8F9186CDEAE365BD2FE4A3FBD3C96A4F26B682D26EFEF9E266FF00E1287380B2C702C900F1E576A4751617B6AA7ECCCF7C523648';
  i(6)  := 'DC58F69B6B9A688215A6D959264C68A4356F8E371AEEB730135EA8369111011110111101729C5198376264DE96D601D4BA660A5D5A8DB8E79FCBB3E28EF592606BC446C77D2DCCFA2083DC7BD602F5FBA97BA8121ADED1AD06A059F335E6B137BD0666CD';
  i(7)  := 'A57A2C6C1657E35A49F8681656328A0CC0D05677727239F64E23BBEF1E2FF98C0FB2AB934BDB68E97EA558AE10ED0126C689A3BE27491BBE7CE5E2BA53DA83B4444404444044440506F1CB69876D08E30EE61143AB41069D23C937D794314E45560DFBC8';
  i(8)  := 'F69B5B2DE5BFAF2015A68C7726BFB50696CBC6BC0CD97E03DD1BD2DF90E35E8C5E3C2755D5ECF84B777326420812E763B584F71F6513DC6BE56E5CB3020C910EF3D7EC17D386ABE623A1F9EBE817EFB3B283676B6CCE4871721BF9656CCC759FD482675E';
  i(9)  := '9E1C8F8BEAA46E06EDD7372DF8C4FE1CAC2F68B341F1D6A0756DDFF88F05C7E4623A4D881C0170C6CCED559A66542059F06F3C4DF37AD8E1965166D9C53757272FEF639B5F541659111011110111100AABFBE7D9DAB983FB99FEB2B8FDD5A05136D5E104';
  i(10) := 'F93B4B22674B1450C92B9CDA0E7C946BFA680BF341CE6F8B9B1EEE6CA89BA07B1F2B878B8B4127D6477AA8EED485C5E8C43362E1B5C5CCC7C46004D5DB9CE166B4BA635472F7A0FA8C9D7E67ECB235DAAD780F67CCFF000164E641DBEE8D3F62ED66135F';
  i(11) := '818EF1F1D6395EEFE43479AF1772EC6D3C4D35F79C7AFF007B175BC0DC664B939714AD6BE37E3B439AE16D2D12EB63CD762383D1C5B460C9C690B6264CC7BE292DD41A6FF0DFDFDE068EF54123A22202222022220222208B7899C2D9B3324E563BDAE716';
  i(12) := '35AF8DE794F60502C777791AF9EAA28DA9B859F09224C49FE6D8CC8DFDD1D856A51055B878759DEE2FCA38F20635CD1CA58E1316906E411D73728ECEBD6FB812B1ECEDC7CE9B56624E47898CB1BEAFA0AD42208B3847C3DCAC2C8972324363E78BD9B181';
  i(13) := 'E1CFD5ED7173B97B23F2D55FC7E0A534440444404444044440444404444044440444404444044441FFD9';
  l_blob := varchar2_to_blob(i);
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(3, 'Jacket', 'Fully lined jacket which is both professional and extremely comfortable to wear', 'Mens', 'Y', 150, l_blob,'image/jpeg','jacket.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 4
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB0084000906061010101512131215141316151214171614181A1417171719161815181C1A121720261F172525191713212F202428292C2D2C171E3135302A3529372C2901090A0A0E0C0E190F0F1A';
  i(2)  := '2C241E222D2A2D2F2C3535352C352E2D2F2934292929352B2A2B3535352A2C29292C2A342D2C29342C2D2C2C2C2C292C2C342C2C352CFFC00011080068006803012200021101031101FFC4001C0001000203000300000000000000000000000607030405';
  i(3)  := '010208FFC4003710000103020304060806030000000000000100021103041221310741517105061361A1C122233242728191B11492A2A3B2D1526282FFC4001A010100020301000000000000000000000000030602040501FFC400271100020202020003';
  i(4)  := '090000000000000000000102030411051221314113224251618191E1F0FFDA000C03010002110311003F00BC5111004444011141FAC1B55B6B5B936EDA6EAA5BED39AE01A1D3184647111067E8BCDE892BAA76BD416C9C22AEAA6D928013F877FE613E22';
  i(5)  := '254CBA03AC142F688AD45D2D3A83939A6261CDDC5134CCEDC6B6A5B9C7474D1117A40111100444401111005C3E9DEB8DA599C351E4BE27031A5EE83A4C64D983A90BB657CFDD2DD2A6ADCD4AC7DAA952A3A383412D689F85AD1F258C9E8DEC1C659136A4';
  i(6)  := 'FC1124EB46D66E1CC70A34FB1A64118DDE95523491193350273EE2A056142BBDA5CF034903780738E3BF7AE81AA5D2665A72EF1CD65B7799D00CA26758EE50B932D3461D54BF70E50E44F70D4ACDD03D64BCB0AC1C3D597000080585B3935EDEEDC7519F';
  i(7)  := '195BF6B4435F53862007289F3F058AF28626E1DE41FAEE45226BA88DB1D48B2BA2F6B54B26DCD1753397A74FD630EE397B4DCFE2E6A776B74CAAC6D4638398E01CD70D082A84B6A62A31BC3D1EF22449F35676CDAEBD53E8C9863839B3B83B51F513FF00';
  i(8)  := '4B38CF6F4CE0721C742A83B6BFC133444529C108888022220305FDD0A549F50890C63DF1C7082EF25F33BEB132749CE3C4F8AFA33ACD6B56AD9D7A5440351F49EC6C9812E1875E44AA3BA5FA917F6F4DCE7DB54710DD698ED47EDCC6BC372C2475F8D946';
  i(9)  := '3DB6F4CF4A00B9808C21AE683DFDFE2BDC320653C6777D1712C6EF0B58D20E33220FBB2E20E474D4A945D570D69F467700B5DAD168AAC528ED1A93C0CCC67A2C8FA1886872D0C792F177488C21870983A18CF285B02BBC522E3ED0827CD784DB39D60C75';
  i(10) := '3AC448C265E3B88D72E4E2A7BB3CBD06EC86990EA6F197169698F979AAE9B56E2E6E0368D17D47B2A104526927B39D491ECE8333C558DD5DEA5DF50BBA35C06D3A6D3EB18F7CB9C1C0830D6820113C46614B18BDA672B3AFAFD8CE0DADFC8B291114E53C';
  i(11) := '222200888802222028DDA7D916F4D623A3E95178F94B3EED586A36699E454C76B960C9B6AF3E98754A51C5A407EBDC5BFACA81DDDC3832018DC56BD9E65BF8B96F1D337A98070F2FE97B5564D3A83FD4FF006B0503EC99990392DCA6062238823C14475B';
  i(12) := 'D0E9EC72CCFE32F2A6EECEDC7CDF2E3FC55B4141F6516EC6DBD53EF9AB0EE4D680DFBB94E56DC7C8A3E7BDE44C2222C8D208888022220088BC140553B55E95C7774E8839526623F13E0F835ADFCCA1784B839DBA16CF58EEFB6BCB8A9C6AD48F85AE2C1F';
  i(13) := 'A405AF484D277082B5E4FC4B9E157D298C7E86D3D863271D32E208EF596C6F7161275DEB568BE1E1A4983946FDDC744AB43B27EB91321466FEFD49FECE2F705C56A07DF870E627C89FA2B182A8FABF5B0DD51AA379603C89C3F6255B816C56F68AAF2F57';
  i(14) := '4BFB2F897E8222290E38444401111005E095E57822501F383BD22493AB9C4FCCCAF5AD5096963781FB2B96E7661D1EF74863E9F731E437E4D7481C864B09D93F479D7B523876900F380A1E8CB24394A5475A65436D544B49DD9C9D4F32BB97943188CB16';
  i(15) := 'A2558CCD96F470F71F1FE38CC7DA7C56C376756000182A40F67D63FD1E466578EB6C9A3CC511F069FF007DCAEFA1AA10583396BDBFC82BA82E359F53ACE910452920C82F739F9F18263C17682CE11EA72391CC8654A2E09AD0444521CC08888022220088';
  i(16) := '8802222008888022220088880222203FFFD9';
  l_blob := varchar2_to_blob(i);      
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(4, 'Blouse', 'Silk blouse ideal for all business women', 'Womens', 'Y', 60, l_blob,'image/jpeg','blouse.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 5
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB004300090607080706090807080A0A090B0D160F0D0C0C0D1B14151016201D2222201D1F1F2428342C242631271F1F2D3D2D3135373A3A3A232B3F443F384334393A37FFDB0043010A0A0A0D0C0D';
  i(2)  := '1A0F0F1A37251F253737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737FFC00011080068006803012200021101031101FFC4001C00000104030100000000000000000000000002';
  i(3)  := '03070801040506FFC4003C100001030203020A0803090000000000000100020304110506210731121314617182A1B1C1C222324151728191D2335292424554738394A2B2D1FFC40014010100000000000000000000000000000000FFC400141101000000';
  i(4)  := '00000000000000000000000000FFDA000C03010002110311003F009C508420179BC633B60D83626FC3EBE49992B1AD7173622E68B8B8DDAF62F48ABBED0AB5D579BB1491AE04366318E8600DF04131479FB2C49FBD58CF8E37B7BDAB6E3CDD9724F571BA';
  i(5)  := '0EB4ED1DEAB63A57FB7BD20CEFE7FAA0B3273565E1BF1CC3BFB967FD4D3F38E5B60BBB1CA03F0CC0F72AD3CA1C3DFF00558E3DF6B0EF4162E6DA1656886B8AB5FF00CB89EEEE6A5E0F9EB03C67128B0FA09667CD28716F0A12D1A024EA7982AE8C91C5BA';
  i(6)  := '903E6BB993AB8D0E67C2EA4BF82D654B0388FCA4F04F61282CAA10840210840210840DD44AD8209267FAB1B4B8F40175576BA674F5124CF37748E2F71E726E558CCE953C932A62B28363C99ED1D2E1C11DEAB74C7D22835DE9052DC9B28125BEE40D12BD';
  i(7)  := '8B0832D3AAD984906ED363EC3CEB5427E2DE82D2E0F58310C268AB01BF1F0324FAB415B8BC9ECB6AF9564AA104DDD097C27AAE36EC217AC40210840210841E3B6AF51C464E9D80DB8E963676F0BCAA0294EAA69DB55470306A082FF89505FF00A5A47994';
  i(8)  := '2B26F40D9DE9B725949720C0DCB077AC8DC90E3AA0504F446C994E30A09BB62753C66055D4C4EB1557087439A3C5A548CA21D86D4DABB14A527D7863900F8491E60A5E40210840210841126DB6A2F5B86D37E485EF3D62079545321520ED86A38DCD463B';
  i(9)  := 'FE153C6DEF779947B2A045D61601438A049364D9372B2F49BA07014E34EA99BA5B5C8241D8ED518338C71DF49E9E48FB03BCAA7855B367F55C97386132DEC0D43584F33BD1F32B2680421080421082BDED2AA394670C4DD7D1B2060EAB40F05E4252BB59';
  i(10) := 'AAA795660C4A606E1F552B874708AE1C9B90360A1C74491BD04E8812E29008BACBB7240DE81C26C02530A6DC74012A3D107470D9CD3564150D363148D907C883E0AD5B1C1EC6BDA6E1C2E3A154C8BD603DEAD0E57A8E5796F0BA8BDCC949113D3C11741D';
  i(11) := '44210804D554A20A696676E8D85E7E42E9D5C7CDF3F27CAD8B4B7B114920079CB48F1415B2A1C6491CF76F71B95AB22DE923209D345AAE8CD906B5B5582344F18CAC7166DA20D770D124356C188958E28A060EAEE64B60D53BC494A1111B9011FAC158CD';
  i(12) := '9854728C91869BDCC6D7C67AAF70EEB2AEEC88837B153BEC6DE5D949EC274655C807410D3E283DDA1084024C91B2563992B1AF63858B5C2E0FC90841C2C4325E5DC42E67C2A06B8FED420C47FC6CB8D36CB32E48EBB456463DCD9EE3B41421032ED9365E';
  i(13) := '3BA7C407F559F6A6CEC8F02FE3310FD71FD8842049D90E097D2BF10FAC7F6A50D91E0237D66207AF1FD8842075BB27CBA37CB5EEE999BE0D5B94FB33CAF08F4E8E698FBE4A87F8108420E952E4BCB74AE0E8B06A4E10D417B387FED75DD631B1B0323686';
  i(14) := 'B4681AD16010840A421083FFD9';
  l_blob := varchar2_to_blob(i);   
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(5, 'Skirt', 'Wrinkle free skirt', 'Womens', 'Y', 80,l_blob,'image/jpeg','skirt.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 6
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB0084000906061410101214121216151516141614181713141A1816141C141815151516151B1C1C26212320231F1E131F2F2C2F27292C2C2F161F3135303635282D2C2A01090A0A0505050D05050D';
  i(2)  := '291812182929292929292929292929292929292929292929292929292929292929292929292929292929292929292929292929292929FFC00011080068006803012200021101031101FFC4001C0001000202030100000000000000000000000607050801';
  i(3)  := '030402FFC4003D10000103020207040607090100000000000100020304110521060712314151712261819113233242A1B1145262C1D2E1F0243344547282B2C2D143FFC40014010100000000000000000000000000000000FFC400141101000000000000';
  i(4)  := '00000000000000000000FFDA000C03010002110311003F00BC51110111101111011110111101111011110140F583A78EA3F57016FA40369C5C2E1BC436DCF8F9298E295ED82192476E6349EBC8789B0F15AF98BE206A2491CF372F2E24F3BE6505ABA05A';
  i(5)  := 'CA662168A4D964F6BD87B3201BF66FB9C3336CF2CC1DF69C02B50A96B1D04B76B8B5CC75C106C4169B823C6C56C46ADF4FDB88C5B32102A236F6DA32DB1BBD2307CC7027910826C8888088880888808888088882BFD6D62A590C7103ED12F7746E4D1E64';
  i(6)  := '9FED54CBA5ED2B335BAEF5EDEE89B6F372AB2475B3418CC5E2ED0773C8F51F97C9756178D4B49511CD0BCB5EC21C08F88238822E08E457BE46FA46969F0EE3C160DF11B9B8B20DAED04D358F14A612B2CD7B6CD963BE71BBF09DE0FDE0A922D4AD0ED289';
  i(7)  := '70DA96CF11B8DCF65FB32378B4FCC1E0405B47A3F8F455B4F1CF0BB698F1C77B48F69AE1C083914192444404444044440444410ED6268D7D2610F68ED301BF7B7F254562942F89C438640FEAEB691CCB8B1556E99E0F1898B0D838E6D07DE0791E07AE5D';
  i(8)  := '37A0A4A69B657B288B26F686FC89E20F023F5CD7AF1EC00B412D19663A11BC77151FC2EB0C3280ECC6E2398E36F9F820CA55612633CC70206F521D5D69BBF0AA8B3EE69E42048DFABC048D1CC7C465CADDEEA5CAD7BB1D623967B9C147714A32D26F641B';
  i(9)  := '554954D958D7B1C1CD700E6B9A6E1C08B820AEE5436A9358BF4478A4A97FA97BBD5B9C7289C7813F549F239EEBABE1A5072888808888088880AB8D679D99E99DD07992D3F3563AADF5B86C694FDAFF0076A0C1CBA28F9E9E69E21B45993E203F78DB5DC5';
  i(10) := '9F6DB911CF31C55618BE12369AF6EEC9C08DC415B1FA0B1FECA4F391C7C834281EB2F43442E74D10F5523892D0328DE45DC07D97E67B883CC208668A5689186171CDA2EDBF2E5E17F885D7A47426DB43DDDFD387928E42F7472ED372734DC594D61C4595';
  i(11) := '515F739B9381E1CC1EA82BD94E7FAC95C1AA8D6B36CCA3AB7804766295C72EE63CFC8F0DDD2B0D20C3FD11ECFB27E1DC5606F641BA60AE56B7686EB9AAA89A23947D2221900F367B4726BB9771BABB343B4F69F138F6A2DA63AF62C900072B5F64836210';
  i(12) := '4951110111101569AE007F67205C037F27372BEEE0ACB5F2F8C11622FD73411DD01976A8C1D923B6EB6D0B5F71B8EECFE0B2D8D6182A6092277BED201FAA77B5C3A1B1F05ED01728356B48680C1507686C9CC11C9CD243879DFC9634BDF1BB6E3716B871';
  i(13) := '1C7B8F30AE1D6A68697174EC1D9766E23DC70CB68F7385BC41E6AAA9E89C066DBF7B730507C9C484E3B6D0D76E3B2323D415D35182C4FCC12C3F6736F913971E2B0F575258E22C4750BE63C71C3864833B4B81C6CB5C17FF0051ECF90FFAA59875596869';
  i(14) := '63B64B7D92DCB67A5940E2D261EF34AC8D2E95C4398EA105E1A3BAC4C832A8777A41C7AA9D53D4B6468731C1C0EE2372D68A7D2F86D62F1E2A41A3FAC2FA3BEF14991DED26ED77820BF1160F4634AE2AF66D466CE1ED32F9B7BC73088338888808888387';
  i(15) := '36EB0788683514F732534773C58360F9B6C88823188EA4A924BFA392688F2DA6C8DF27B49F8A8F566A1A41FBAAA89DDD2425BF16B8FC9110626A35215A3DDA67F491C3FC98BC6ED4A56FF2D1F84CCFC972883ACEA3EACFF0C3C2767E25CB3515567FF168';
  i(16) := 'EB3B7EE251104FF56BAB0930C99D2C92373616FA3639CE19DB371361E43C511107FFD9';
  l_blob := varchar2_to_blob(i);    
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(6, 'Ladies Shoes', 'Low heel and cushioned interior for comfort and style in simple yet elegant shoes', 'Womens', 'Y', 120, l_blob,'image/jpeg','heels.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 7
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB004300090607080706090807080A0A090B0D160F0D0C0C0D1B14151016201D2222201D1F1F2428342C242631271F1F2D3D2D3135373A3A3A232B3F443F384334393A37FFDB0043010A0A0A0D0C0D';
  i(2)  := '1A0F0F1A37251F253737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737FFC00011080068006803012200021101031101FFC4001C00010002030101010000000000000000000005';
  i(3)  := '07040608020301FFC400381000010303020404050204060300000000010203040005110621123141510713617114224281913252152362A12453637282D1A2B1F0FFC4001501010100000000000000000000000000000001FFC400141101000000000000';
  i(4)  := '00000000000000000000FFDA000C03010002110311003F00BC694A502A3EF979816280B9B749096194EC33B951EC91CC9F4159921E6E3B0E3CF2C21B6D254B52B92401924D7366B5D452F545E152DDE311C12988C7F968276DBF72B627D76E82836CD43E';
  i(5)  := '30CF7D6A6EC515B8AD720EBE02DC3EB8FD23FF002AD51EF10F55B8E719BDC849CE7094A123F01352965F0C6E72A22A7DF64B3658294F1295277584F729C809FF009107D2A22F0CE8C8414CDB9DBC5CDD1B79C5C6E3B5EE3282A3F81EF41296AF15F53C25';
  i(6)  := 'A7E2643139B1CD2FB4013FF2460FE73568E8EF11ED3A95C44573306E0AE4C3AAC870FF0042BAFB1C1F4AE715A92164A028273B027247DF033F8AF685F25209041C820E08A0EBFA5555A07C5186AB6B70F54CA2D4969410996B4929713D0AC8E479824EC7';
  i(7)  := '19CE4D5A2C3ED48650F47710EB4B1C485A1414950EE08E741F4A52940A52940A52941A9F8A52171F43DC036A292F16D824765B894ABFB13505E186908ED369BFCF682DF7093112A1B348E5C7EE7A1E83DEA7BC52643FA12EA8512308429247421C491FDC';
  i(8)  := '57AD03A921DF74D32EB45B6DE88D25A92C0DBCB2918C81FB48191F8E60D055DE31EA67AE77D72CEC2CA6040504AD20ECE3D8C927FDB9007AE4F6AD023449535DF2A1C77A439FB196D4B57E003562F87F62B56B2D557E9376794EF95294FA2303C21D4AD4';
  i(9)  := '77279E0600C0EE3DAAEC83062DBE3A63C18CCC7653FA5B6501091F6141CCADE84D54F27891609D8FEA4041FC2883587334CDFADC92B99669ECA0735AA3AB847DC0C5756E053141C8C405455BA9C6C7814074CEE3FF005531A335A5D348CC4AA2AD4F4052';
  i(10) := 'B2F425ABE457729FDAAF51F7CD6F5E369B6AAEB6D851E2B0998E381729E6D094AD4951C2524F5E4A3BF2DBBD6ADAE7C3D9FA55DF3D2AF8BB6AD5C289094E0A09E4163A1EC46C7D0ED41D0563BB44BE5AA3DCADEE7991DF4712491823A1047420E411DC56';
  i(11) := '7D541E05CF71A7A7DA1649696D894D8FDA73C0AFCFC9F8AB7E814A52814A528237525B05E6C53ADDC5C26432A42547E957D27F38AE6885367D8AE725A0A7A2C81C6C3C1270A4F45248E447A1EC08E86BAA6B41F113C3C6751955CADA50C5D529C2B8B644';
  i(12) := '8039057657657D8F42029AD33709BA5EFF001AF36FFF0012D20F0BCDA0E0B8D1C71248E9D083DC0AE97B55CA25DADECCE80F25D8EF24292A1EBD08E87B8E95CBF3A14BB5CD7624D65C8F259570AD0AD8A4F3E9E841C8EF5F045DA75B9F0F4194F4774F35';
  i(13) := 'B2B2851F729C6683ACEA27545FE1E9BB3BD719CA1C28D9B6F382E2CF248FFBE8013D2B9FE1789FAB22A0245D14E8FF0059A42CFE48CFF7AC0D45AAE6EA87D976F8E38EF929E16DB688420773C38E67A9F4141F37E64CD51AB6338F28A9E992D0949DC6EA';
  i(14) := '524647618C63B003B57466ADBB592DD6A7DABF38DA997DB524C6FD4B781E894F3FBF21DC5739C290CC490DCA88D3A87DB3C4DBA5F21493DC70E2BD4B96F3E56E38AF995BA959DD5EE4EE7EF41657821143970BC5C30A094A1B6194A8E4A504A95BFAEC33';
  i(15) := '56ED695E13D8E459B4D71CC6CB4FCC73CE2DA861484E004823BEC4E3A66B75A05294A05294A05294A0ABBC66D28A99153A82DE83E7C64F0CB4A47EB687257BA77FB1F4AA8176DF8948217C0A1CF6C8AEAF5A429252A00823041EB5CEBA8D36987A9E6C1B';
  i(16) := '3B9C7110E14B791F2A55F52127A849D81F4237C6486A122D3263E0E50B4138E249D87BE6BE8DDA25A802128238B03857C5939C606399CED5B260293C2B190AE7BF3A92D1326DF68D4911DBCA95F02824B2E1C70B2E7D2A5FA0DFD8E0F21B4548DAFC22BE';
  i(17) := '3A10674B851527984953AA1F6C01FDEB7ED33E1D59AC6EA24B8173A5A082975F038507BA503607D4E4FAD6E092140149C83C88AFDAA85294A05294A05294A052958777B946B45B24DC26AF823C76CAD6473C0E83B93C80EE68350F153569B0DAC5BE03BC';
  i(18) := '3739A9212A49DD86F929CF7E89F5DFA550120FC9C29CA427F4E3E9C72A97BFDDE4DF2ED2AE737679F56423390DA07E940F403F2727AD43A905C74253939EDBD153167B8194DF03DF2BA9C8CE3F57B7AD4AFF000D7E4595FBA17984456E488BE5F998754B';
  i(19) := '201C84E318DF3B9E84F4AB4346787F0A1E915C1BB470A933807241070A688DD0127A14E739EE4F4AADF51D8DDD37777624A5A1C570F1B6E8C0E341C80A23A72208F7C6D8A827344F882AD36D356BBD87245BF931211BA981FB4A7994F6C72DC0C8C01724';
  i(20) := '394C4E8AD4A88EA1E61D485B6E20E4281EA2B951FB8625F98CA12AC0FA86C7D48AB07C2DD692ED2C26D52E3AE4C4528B8D96C7F319493F3AB840DD3939C6C79E33CAAA2F0A57869C43CDA5C69695A160292A49C8503C883DABDD0294A50294A502A9AF1A';
  i(21) := '7537C44C6F4F4458F2A390F4C20F35F3423EC3E63EA53DAACAD657E469BD3D2AE4A485B88012CB67EB715B247B6773E80D7324B79F9121D7E438A71F75656EAD5CD4A27249FB9A0FC52F35677849A3152A5A2F7716BF90C2B8994ABEB70723EC9E7FEEC7';
  i(22) := 'ED35AD787BA45FD4B754970291099214F383B761EA7FFB95744C58CCC48EDC78CDA5B69B484A109E400A0FAD69DADB4041D52EA257C4390E5A5210A75090B0B48E40A491B8CEC41FCED8DC6941CC8CE96B833A997654B28952DB7BCBF2D2ACA5C2372A51';
  i(23) := '1FA5183939DFA73ABBB49586169990F452C244996028C8E227CCC0DD033C80DC81FF0059397FC21367BDCCBD436CBBF19C3F14D0402A0075475CF529EBEE003273586AED6ECC77C0E24F1B1211BF02BE950EFBD061292BB0B8A71B495DAD64A96DA464C6';
  i(24) := '2772A48EA8EA47D3CC6D90269B5A5C4256DA8290A00A54939041EA2A2ED53E44982D7F106C4696DA0194927E549190483D8F0939E83D6B2AD51DA8D0D2861050D152968472090A513803A0DF974E541994A52814A52830EED6C877782E42B8309798739A';
  i(25) := '4F4239107A11DEAABBD784D304F6CDAA434F445AF07CF570ADA1F61850FC1F4A5282CDD3D658B61B5B5061A70840CA958C15ABA935274A50294A507E1008C1E551E2118921C7A338A432EE4B8D04F10E2FDC07427AF43CF9E495283CB514497788B3E547';
  i(26) := '18C85270B788E455D703B1DC9E7B7393A52814A5283FFFD9';
  l_blob := varchar2_to_blob(i);
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(7, 'Belt', 'Leather belt', 'Accessories', 'Y', 30, l_blob,'image/jpeg','belt.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 8
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB0084000906061412111514131415131316151B151716171814181512181A1815141B1C1E161A1C261E1819241914161F2F20232A292C2C2F171E3135302A35262B2C2901090A0A0E0C0E170F0F17';
  i(2)  := '2C1C1C1C2C2C342C292929292929292C2C2C2C2C2C2C29292929292929292C2C292C292929292C292C29292C2C292929292C35292C29FFC00011080068006803012200021101031101FFC4001C0000010501010100000000000000000000000304060708';
  i(3)  := '050201FFC40046100001030203040507060B09000000000001000203041105214106071231135161718122425291A1B1D114233293A2C11517435462637292B2D3F0162453647382A3C2D2FFC400160101010100000000000000000000000000000102FF';
  i(4)  := 'C400191101010100030000000000000000000000000111213141FFDA000C03010002110311003F00BC5789A60C6971E4D049EE02E57B4C31E9B8296777A30C8EF531C7EE4113A2DF561B21B748F60D1CE8DDC27C5B7B78D97521DE661AEE55910FDA25BF';
  i(5)  := 'C402CD94381C5281F49B90BD8DFDE14830BC368A21F3D46EAA1E936A658C91DAD02C7C08545F876F70FF00CF69BEB59F15F59B7340795653FD633E2A9E6E278735A4438231C7AE698BADE243DDEE509C7A0964771474915330694C5FEDE279B9F00A2B4D';
  i(6)  := '9DB2A2FCEA0FAC6FC528CDABA33CAAA0FAD8FE2B28C523864E9DCD3D52464FC57D329D2584FF00B2C7F855C46B11B454D7B7CA20BFFAB1FF00E97C7ED2D28C8D4C008D3A58EFEABACC786C14EF67CF4B58E7E8DA786011839FE51F25CE9E68F14DDDB2A6';
  i(7)  := '491C58E9238BCDE91C1EF03B4B4347A87AD06963B7F41D23221531BA491E23635A788B9CE3C20642DCCA902CC7B25B32D8710A325E5EFF009543C8587D369E67DCB4E05142108440B89B6D2F0E1D567FCB4BED8DC3EF5DB518DE6CFC184D59FD491FBC43';
  i(8)  := '7EF419DE9CBA2601C1F481B125A01B5AFAE5CC7AD23F87C8C88B5B4BA5057F14638B87C9BF55FD7D592468AAF879B1A7BC2AA5A3DA72340BD9DA4CCD80CF4CF2F6250BDA73E065FB8251D4CC78B88D808D2D9140D7FB400F300FB7DE1291E3510F31BEA1';
  i(9)  := '97B126E8870348863CC751CFDB9242091872E8197EBCFE283A916D3B75B04A3B69A2E77CD730D3869CE08DC3BDD7F7A467E0360210DF177C532096ECF4FD257D1DB3FEF515CD9E39383B50068B450599F09DB110D4529783D0C52B5C7845DFE4E595F99C';
  i(10) := 'FDAB4950D63658D9230DD8F687B4D88BB5C0381B1CC64543C2E8421102AC77CFB4AE6D2CB4CD85EE6BBA3E965360C602EE36B46772E3D19F515672A3F7D78D033BA9D84969E8BA5F45AF6F191E6E4EB39BCCF9DCB552AC560D8C3B88736DEE0256E2E99B';
  i(11) := '64B725EC3C95A0F2C4794DD74EA4AC789581EBB1F726AC9085F248C104806E02A3AD455CC735A350125554FAB466B90C8C8B1053B6E22F1CD40E63AA3A85E2595A73D5349B102ED2C5367D41B141D8D89A26546274B0CAD0F8DF210E69E4E1C2E247B15E';
  i(12) := '3B19B42E8AA64A09448F6B669194F396D9B270B448E61232E30093965D8059533BA8F2B19A3EC738FAA294AB77656432E335ADCCC74D248F06DE7CE218F2CF9010483BC958B39D6A75CAC64210B4C059837BE0B719AB00901DD1B8804D8FCCC5CC6BC8AD';
  i(13) := '3EB386FAA90B7187B88CA48A3703D766F07BD85042298129CC51A4A38C8E495634AD2968E1CF34EE3918D06FCB84F8260E04F5F82F0EA736E45076592C190245D7A73A1B5B22B8DF213E89F7AF0EA6B6847AD4C0F6AA9A3232365C7A88ED9258C2742937';
  i(14) := 'B0EAA8956E5A3BE334FDD29FF8645696E71DD2CB8A5569356900F586F1B87B250AA2DDD55982AA59B97434953203D44445ADFB4E03C55EDBA2D9F7D261913246F048F2E95E0F305C6C2FDBC0D6ACA266842100A0DBD5D82FC214E1F101F2986E63FD634E';
  i(15) := '6E8C9EDB022FA8ED2A7284198309ABA2638475B47302D3C2F7C7348D7B48C8DE176BD6010AD7C3374F85D444D9617CCF8DE2ED736677B88C88E441CC275BCEDDEB6B2333C2D1F2A60BD87E5DA3CD3D6F03E89F0E445A07BA9DAE34B58DA671F99A8706D8';
  i(16) := 'F9921C9AE034B9B34F78EA544DDFB8EA13C9F523BA469F7B0A4BF11547FE3557EF45FCB5642134571F88CA4D2A2AC773A1FE5A6357B8B1F92AD947648C6BC7D92D56AA14148546E2EAC5F867A77F789597FB2E5CAAADCD622DE51C527EC4ADFF00BF0AD0';
  i(17) := '8B9BB43B4115153BE799D663472F39EED1AD1AB89FEACAE8CEB0EC45532B22A49A3313AA0B5A47131C7A1E36979F21C6C2CC3CFD12B4DB459561BB085F5D53362738F2892C8FA9B95886F635966DF52E72B41281084280421080545EF6B64CD25632B211';
  i(18) := 'C31CAF0E36E51CC0F178715B887687762BD133C5F098EA617C32B7898F162351A820E841CC1409E038BB6AA9E399BC9ED048F45DC9C3C1D71E0BA0AB1C322A8C124735E1D3D03DD7E91A2E62D2EE68FA26D607CD361620E4AC7A2AE64CC6C91B9AF6385C';
  i(19) := '39A6E0FF005D4817422EA05B73BD982883A386D5153CB85A7C88CFE9B86BFA233EE4123DA9DADA7C3E132CEFB68D60CDF21EA6B75EFE435547B66ACDA5AE0338A9A33736B98E9D87D8F95D6CBAFB00C9CE0FBBCC43199FE535CF7C309F39C2CF7379F0C5';
  i(20) := '11FA2DED396B672BBF00D9F868E16C34EC0C8DBEB71D5CE773738F59452D846151D342C8626F0C71B785A35EF27524DC93D653C42110210840210840210841F085C49F63E024BA2E9299EECCBA9DEE8B88F5960F21C7B4B4A10819D5EC13651C32D65748';
  i(21) := 'D3CDA660D69EF0C636E97C1B602869487454ECE31C9EEBBDC3B8B89E1F0B2108242842100842100842107FFFD9';
  l_blob := varchar2_to_blob(i);
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(8, 'Bag', 'Unisex bag suitable for carrying laptops with room for many additional items', 'Accessories', 'Y', 125, l_blob,'image/jpeg','bag.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 9
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB004300090607080706090807080A0A090B0D160F0D0C0C0D1B14151016201D2222201D1F1F2428342C242631271F1F2D3D2D3135373A3A3A232B3F443F384334393A37FFDB0043010A0A0A0D0C0D';
  i(2)  := '1A0F0F1A37251F253737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737FFC00011080068006803012200021101031101FFC4001C00010001050101000000000000000000000007';
  i(3)  := '02030406080501FFC4003A100001030203060305050803000000000001000203041105213106071251617141819113142223A1324252B1C115173343445372D16284C2FFC40017010101010100000000000000000000000000010203FFC4001911010101';
  i(4)  := '01010100000000000000000000000102112212FFDA000C03010002110311003F009C5111011110111101111011110111101111079BB458C418060B5589D502E8E065C301B17B89B35A3A9240F3518D0EF271B967E29AA30E6B0E7EC8D23C37B077B4BF9D';
  i(5)  := 'BCBC16C5BE2783B38223A125DDCE83E8E77A28222A82D3C2F272D1CB1B9AE796F1F3DF4E82C33783452B47ED3A596972CE68499E2F568E21E6D03AADA30FC4E871288CB875653D5463574128781E85734D2E2660B7CE196963A7EAB22BB6864AC6362643';
  i(6)  := '097DACEA99226BA4B726B88B8EFAF2B6AB18DEEDE58DEF1893B2A64C6F797826175BEEB1B67ACE13F364A70D2D676248E2F2CBADF259DB1FB6987ED3B1D1C3F2AAD8389D0937BB6F939A7C469D42E7A7161177BDED63756B4DAFE7AAB13C3253BA39DD7F';
  i(7)  := '8802D68362D3E163A83D47D17671759A28D7775BC838DCEEA0C71D4904E1A3D948D2E6179D08707139F5BE7C82925A43802D2083A1083EA222022220222208E77D4C95F825198AF66CC4BADDB2FCCA82DF62E37162A7ADEBE314F4347052D652BE5A7973';
  i(8)  := '7C91E6E8B501D6E5716F0CC8B7230C5751C53B9D35048D9E1E6DC883C88D41EEA8F3006AAD8EE0D150F8DCC3620854B49BE6A0CA63F319E8AF0F660BE49AEEE21C0C00663A0EA561870009571B3BF87D9C4DBC8EE795875406D33DCD2F692DBEA49E2254';
  i(9)  := 'B7BA4DAEA99661826253C669D9186D2991C039A464182C05DB6D01CC5AD722D68CE96131C5C25DC4E39B9C42A656BA2904911731C0E446483A9D1441B13BCA9E00CA2C7499A219367FBEDEFCD4AF455B4D5D009A92664B19F169FCF920C844440444411D';
  i(10) := '6F66036A2A830BDCC0D7B0C8CD4136F848391BF2B8391D74511D4E1519799699E6391BABA2BB4B7BB7223E8174ECF0C55113A19E364B13C59CC7B4383875056A18C6EEB0BAD71928647D1C96B0681C71FA1CC79103A20829FEF31464D7402A606EB34560';
  i(11) := 'F60E67416EE00EAADC942D9A175450C8268DBF6AC2CE67F93750A6EC3B76F08A231E21516A86DC472528B11992092467DBC39AD136A761ABB01A9155070C763F2EAA16FCA7DFEEBDB9F0DF9660F271CC047D636B1D4ABF010C370003E36F155D5811CAF6';
  i(12) := 'D543EED35F8AD7BB08BE563CBC2F98EB7C95B65B40420F4A19B9155C8CF697239AC069234579B339A73CD052E0E8DF9123B2D8300DA29B0991AF8EA248EDF81C73F25E23A40F377B2EADBA4846B1DC77412F615BD3A41C2DC49B76FE368B1F4D3F25BE60';
  i(13) := 'F8C61F8D52FBCE19551D4457B1E139B4F223C0AE5D9AAE2D1B134755B66EBB1F6611B490B789DECAAC18A4634EB95DA6DCC11F53D50742A2B54D5115553C5514EF12432B03D8F1A39A45C1F44417511101512C51CD1BA3958D7C6F04398E170E1C8855A2';
  i(14) := '08DB6AF768DA90E9B057340B977BACCEC81E6C77879FA81928B716D96ACC2A42DADA49A94DF22F670B4F670F84F95D74DAF8E6B5ED2D70041D41D0A0E56F71A96FF0E5047FCAC7EB974F05F1D057DFF976BEB73FA02BA46AF64F00AB25D36134BC475732';
  i(15) := '3E027CDB65E7CBBBCD9A93FA3959D1B5327EAE515CF0E8AB2D673E368EAF3FE9597C329FB75110EC5C7FF2BA1BF767B317CE9AA0FF00DA7FFB5759BB7D936104E15C647F72A2575FC8BACA8E6E7C3133396779FF0018C347AB8FE8B67D95D8FC6F1B95A7';
  i(16) := '0DA092280E4EAA9EED601E3F111F176683D974061FB338161AE0EA1C1E86078D1ECA76F17ADAEBD641838161C308C1E8B0E12BA514B0B22123858BAC2D7B22CE444111101111011110111101111011110111101111011110111101111011110111101111';
  i(17) := '07FFD9';
  l_blob := varchar2_to_blob(i);  
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(9, 'Mens Shoes', 'Leather upper and lower lace up shoes', 'Mens', 'Y', 110, l_blob,'image/jpeg','shoes.jpg',systimestamp,null);

  -- Table: DEMO_PRODUCT_INFO - Product 10
  i := j;
  i(1)  := 'FFD8FFE000104A46494600010100000100010000FFDB008400090606100D111214110F101410111510120D0E180E101B101012161C15201412171E1C1F322A23252F1A1E152B3B202F33292E2E38211E31373C2E41262B2C2901090A0A0E0C0D1A0E0F1A';
  i(2)  := '29211F242E31293534352D352C2F2C2D342A2D2C29352D2E2C302C3435352F2C2D2C352C293534342C2C2E2A2C29292C2F2C342C2C2CFFC00011080068006803012200021101031101FFC4001B0001000203010100000000000000000000000607040508';
  i(3)  := '0302FFC4003C1000020102020606070509010000000000000102031104210506071251911322233161A141717281C1D1F0324252B2E1152433437392B1C2F114FFC4001A010100020301000000000000000000000000020301040506FFC4002911010002';
  i(4)  := '010203060700000000000000000001020304111221320531336181911334415171B1F0FFDA000C03010002110311003F00BC4000000000000000000000000000000000004635CF5DBF65285B0B52BCA6A527184E0B762B2BBBE6F3F424C8AE136F78497D';
  i(5)  := 'BC3568B5DF153A6E4BC1EF6E9B1DA953CE83B77A9A6F8DA54ECBCCADF1B80A75976908CBC5AEB2F5359AE7C0AAD7989D9D6D3E8EB97145FEAB5307B5BD1B55673AB0F6A8C9AE70B9B8C26BB68EADF631B42FC255141F2958E64D35808E16A4541CB7651D';
  i(6)  := 'E49BCD3BB4D5F9195A071B273DD94AF1B773E238E76DC8D1E2B5F839C4FBBAAE9D45249C5A69A4E2D34D34FB9A3E88BECDAA5F47D25F8655E36E0BA49B4B9344A0B22778DDCCC94E0BCD7ED3B000328000000000000209B505D5A0EFF8F2F7D2BBF87BCA';
  i(7)  := 'DE7F5F5F5F3B2B6A5FC3A197DE9F5BFB32E76E45677F2B1AD97BDE8FB3BC184635BD75A93F0A8BCE3F330F404BB55EA667EB8ACA8BF1AABCA9D8D668495AAC7DE663A519E5AAF58745ECAE5FB8FAAAD5F3DD7F126242B64F2BE0A5E15AA71FC34C9A9753';
  i(8)  := 'A61C7D5F8F7FCC80024D600000000000041F6A4BB2A19FDF92DDE39473E57E6562D967ED4EDD051CBF98F3F77773B157CDFEBE7F23572F53D2767781EA8E6B8BEA52F6E7F951A4D1157B58E68DDEB8BECE97B72FF069745DAF2BC77A495A0B849E4999AF';
  i(9)  := '4A9CBF35EDFA744EC7E57C1D5FEBC9F3A7449D95EEC572C1D64DB6E35DABF1EA53F916117D3A5CAD5F3CF69F300049AC000000000000846D6256C351E1D37FA4F32AD9CBF4E6CB935F3576AE90C3C6345C7A4A73E91464ECA6B7649C53F43CFD453B8FC0';
  i(10) := 'D5C34DC2B539539ACDC649ABAE2BD0D78ABA3572C4EFBBD0F66DEBF0B877E68D6B7E70A7EDCBF2FF00C35BA0E2B7F3BFA5ACFEBD04C70DA955F4D49D2A152942749749DA39A8CA2F753578C5B59F81E6F641A670D3BFFE58D48AFB4E9E2293CBD52717C9';
  i(11) := '12AC4CD1567BD69AAE7E4B2B62B513A1898E79568BE715F14CB1CAE3643A2B138578B8D7C3D5A4A5D04A1BF0B272ED54B778E5BB7F596396D3A5CDD64C4E7B4C7F720004DAA000000000000187A4F4450C5C372BD28D487A1359C5F18BEF4FC558CC0198';
  i(12) := '9989DE116D5AD44868DC4D4AB4AACA54EA53DC8D2947AD0774EFBCBBFBB85C9480622223B92BE4B649E2B4EF258006500000000000000000000000000000000000007FFFD9';
  l_blob := varchar2_to_blob(i);   
  INSERT INTO demo_product_info (product_id, product_name, product_description, category,product_avail, list_price, product_image, mimetype, filename, image_last_update, tags)
      VALUES(10, 'Wallet', 'Travel wallet suitable for men and women. Several compartments for credit cards, passports and cash', 'Accessories', 'Y', 50, l_blob,'image/jpeg','wallet.jpg',systimestamp,null);

  -- Table: DEMO_CUSTOMERS
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
   VALUES(1, 'John', 'Dulles', '45020 Aviation Drive', null, 'Sterling', 'VA', '20166', 'john.dulles@email.com', '703-555-2143', '703-555-8967', 'http://www.johndulles.com', 1000, null);
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(2, 'William', 'Hartsfield', '6000 North Terminal Parkway', null, 'Atlanta', 'GA', '30320', null, '404-555-3285', null, null, 1000, 'Repeat customer');
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(3, 'Edward', 'Logan', '1 Harborside Drive', null, 'East Boston', 'MA', '02128', null, '617-555-3295', null, null, 1000, 'Repeat customer');
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(4, 'Frank', 'OHare', '10000 West OHare', null, 'Chicago', 'IL', '60666', null, '773-555-7693', null, null, 1000, null);
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(5, 'Fiorello', 'LaGuardia', 'Hangar Center', 'Third Floor', 'Flushing', 'NY', '11371', null, '212-555-3923', null, null, 1000, null);
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(6, 'Albert', 'Lambert', '10701 Lambert International Blvd.', null, 'St. Louis', 'MO', '63145', null, '314-555-4022', null, null, 1000, null);
  INSERT INTO demo_customers (customer_id, cust_first_name, cust_last_name, cust_street_address1, cust_street_address2, cust_city, cust_state, cust_postal_code, cust_email, phone_number1, phone_number2, url, credit_limit, tags)
    VALUES(7, 'Eugene', 'Bradley', 'Schoephoester Road', null, 'Windsor Locks', 'CT', '06096', null, '860-555-1835', null, null, 1000, 'Repeat customer');

  -- Table: DEMO_ORDERS
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(1, 7,0, systimestamp-65,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(2, 1,0, systimestamp-51,'DEMO', 'Large Order');
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(3, 2,0, systimestamp-40,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(4, 5,0, systimestamp-38,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(5, 6,0, systimestamp-28,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(6, 3,0, systimestamp-23,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(7, 3,0, systimestamp-18,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(8, 4,0, systimestamp-10,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(9, 2,0, systimestamp-4,'DEMO', null);
  INSERT INTO demo_orders (order_id, customer_id, order_total, order_timestamp, user_name, tags) VALUES(10, 7,0, systimestamp-1,'DEMO', null);

  -- Table: DEMO_ORDER_ITEMS
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 1, 1, null, 10);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 1, 2, null, 8);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 1, 3, null, 5);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 1, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 2, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 3, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 4, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 5, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 6, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 7, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 8, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 9, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 2, 10, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 3, 4, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 3, 5, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 3, 6, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 3, 8, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 3, 10, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 4, 6, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 4, 7, null, 6);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 4, 8, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 4, 9, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 4, 10, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 5, 1, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 5, 2, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 5, 3, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 5, 4, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 5, 5, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 6, 3, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 6, 6, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 6, 8, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 6, 9, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 1, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 2, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 4, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 5, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 7, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 8, null, 1);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 7, 10, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 8, 2, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 8, 3, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 8, 6, null, 1);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 8, 9, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 9, 4, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 9, 5, null, 3);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 9, 8, null, 2);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 10, 1, null, 5);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 10, 2, null, 4);
  INSERT INTO demo_order_items (order_item_id, order_id, product_id, unit_price, quantity) VALUES(null, 10, 3, null, 2);

  -- Table: DEMO_STATES
  INSERT INTO demo_states (st, state_name) VALUES ('AK','ALASKA');
  INSERT INTO demo_states (st, state_name) VALUES ('AL','ALABAMA');
  INSERT INTO demo_states (st, state_name) VALUES ('AR','ARKANSAS');
  INSERT INTO demo_states (st, state_name) VALUES ('AZ','ARIZONA');
  INSERT INTO demo_states (st, state_name) VALUES ('CA','CALIFORNIA');
  INSERT INTO demo_states (st, state_name) VALUES ('CO','COLORADO');
  INSERT INTO demo_states (st, state_name) VALUES ('CT','CONNECTICUT');
  INSERT INTO demo_states (st, state_name) VALUES ('DC','DISTRICT OF COLUMBIA');
  INSERT INTO demo_states (st, state_name) VALUES ('DE','DELAWARE');
  INSERT INTO demo_states (st, state_name) VALUES ('FL','FLORIDA');
  INSERT INTO demo_states (st, state_name) VALUES ('GA','GEORGIA');
  INSERT INTO demo_states (st, state_name) VALUES ('HI','HAWAII');
  INSERT INTO demo_states (st, state_name) VALUES ('IA','IOWA');
  INSERT INTO demo_states (st, state_name) VALUES ('ID','IDAHO');
  INSERT INTO demo_states (st, state_name) VALUES ('IL','ILLINOIS');
  INSERT INTO demo_states (st, state_name) VALUES ('IN','INDIANA');
  INSERT INTO demo_states (st, state_name) VALUES ('KS','KANSAS');
  INSERT INTO demo_states (st, state_name) VALUES ('KY','KENTUCKY');
  INSERT INTO demo_states (st, state_name) VALUES ('LA','LOUISIANA');
  INSERT INTO demo_states (st, state_name) VALUES ('MA','MASSACHUSETTS');
  INSERT INTO demo_states (st, state_name) VALUES ('MD','MARYLAND');
  INSERT INTO demo_states (st, state_name) VALUES ('ME','MAINE');
  INSERT INTO demo_states (st, state_name) VALUES ('MI','MICHIGAN');
  INSERT INTO demo_states (st, state_name) VALUES ('MN','MINNESOTA');
  INSERT INTO demo_states (st, state_name) VALUES ('MO','MISSOURI');
  INSERT INTO demo_states (st, state_name) VALUES ('MS','MISSISSIPPI');
  INSERT INTO demo_states (st, state_name) VALUES ('MT','MONTANA');
  INSERT INTO demo_states (st, state_name) VALUES ('NC','NORTH CAROLINA');
  INSERT INTO demo_states (st, state_name) VALUES ('ND','NORTH DAKOTA');
  INSERT INTO demo_states (st, state_name) VALUES ('NE','NEBRASKA');
  INSERT INTO demo_states (st, state_name) VALUES ('NH','NEW HAMPSHIRE');
  INSERT INTO demo_states (st, state_name) VALUES ('NJ','NEW JERSEY');
  INSERT INTO demo_states (st, state_name) VALUES ('NM','NEW MEXICO');
  INSERT INTO demo_states (st, state_name) VALUES ('NV','NEVADA');
  INSERT INTO demo_states (st, state_name) VALUES ('NY','NEW YORK');
  INSERT INTO demo_states (st, state_name) VALUES ('OH','OHIO');
  INSERT INTO demo_states (st, state_name) VALUES ('OK','OKLAHOMA');
  INSERT INTO demo_states (st, state_name) VALUES ('OR','OREGON');
  INSERT INTO demo_states (st, state_name) VALUES ('PA','PENNSYLVANIA');
  INSERT INTO demo_states (st, state_name) VALUES ('RI','RHODE ISLAND');
  INSERT INTO demo_states (st, state_name) VALUES ('SC','SOUTH CAROLINA');
  INSERT INTO demo_states (st, state_name) VALUES ('SD','SOUTH DAKOTA');
  INSERT INTO demo_states (st, state_name) VALUES ('TN','TENNESSEE');
  INSERT INTO demo_states (st, state_name) VALUES ('TX','TEXAS');
  INSERT INTO demo_states (st, state_name) VALUES ('UT','UTAH');
  INSERT INTO demo_states (st, state_name) VALUES ('VA','VIRGINIA');
  INSERT INTO demo_states (st, state_name) VALUES ('VT','VERMONT');
  INSERT INTO demo_states (st, state_name) VALUES ('WA','WASHINGTON');
  INSERT INTO demo_states (st, state_name) VALUES ('WI','WISCONSIN');
  INSERT INTO demo_states (st, state_name) VALUES ('WV','WEST VIRGINIA');
  INSERT INTO demo_states (st, state_name) VALUES ('WY','WYOMING');

  -- Table: DEMO_CONSTRAINT_LOOKUP
  INSERT INTO demo_constraint_lookup (constraint_name, message) VALUES ('DEMO_CUST_CREDIT_LIMIT_MAX','Credit Limit must not exceed $5,000.');
  INSERT INTO demo_constraint_lookup (constraint_name, message) VALUES ('DEMO_CUSTOMERS_UK','Customer Name must be unique.');
  INSERT INTO demo_constraint_lookup (constraint_name, message) VALUES ('DEMO_PRODUCT_INFO_UK','Product Name must be unique.');
  INSERT INTO demo_constraint_lookup (constraint_name, message) VALUES ('DEMO_ORDER_ITEMS_UK','Product can only be entered once for each order.');
end insert_data;

end sample_data_pkg;
/
show errors

begin
  sample_data_pkg.insert_data;
  commit;
end;
/


