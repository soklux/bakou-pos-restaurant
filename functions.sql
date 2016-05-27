/*
SQLyog Ultimate v11.11 (64 bit)
MySQL - 5.6.22-1+deb.sury.org~trusty+1 : Database - bakou_pos_restaurant
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

/* Trigger structure for table `sale_order_item` */

DELIMITER $$

/*!50003 DROP TRIGGER*//*!50032 IF EXISTS */ /*!50003 `set_path` */$$

/*!50003 CREATE TRIGGER `set_path` BEFORE INSERT ON `sale_order_item` FOR EACH ROW SET NEW.path = 
  CONCAT(IFNULL((SELECT path FROM sale_order_item WHERE sale_id=New.sale_id and item_id = NEW.item_parent_id and location_id = new.location_id), '0'), '.', New.item_id) */$$


DELIMITER ;

/* Function  structure for function  `func_add_order` */

/*!50003 DROP FUNCTION IF EXISTS `func_add_order` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_add_order`(i_item_id varchar(15),i_item_number VARCHAR(15),i_desk_id INT(11),i_group_id INT(11),i_client_id INT(11),i_employee_id INT(11),i_quantity DOUBLE(15,2),i_price_tier_id INT(11),i_item_parent_id INT(11),i_location_id INT(11)) RETURNS int(11)
BEGIN
DECLARE p_sale_id INT(11);
DECLARE p_price DOUBLE(15,4);
DECLARE p_sale_time DATETIME;
DECLARE p_count SMALLINT;
DECLARE p_item_id INT(11) default 0;
DECLARE p_status TINYINT DEFAULT 1;
   
SET p_sale_time:=NOW();
SELECT COUNT(*) INTO p_count FROM item WHERE item_number=i_item_number;
IF p_count>0 THEN
   SELECT id INTO p_item_id FROM item WHERE item_number=i_item_number;
else 
   select id into p_item_id from item where id=i_item_id;
END IF;
IF p_item_id >0 THEN  
            
	SELECT 
	    CASE WHEN ipt.`price` IS NOT NULL THEN ipt.`price`
		ELSE i.`unit_price`
	    END INTO p_price
	FROM `item` i LEFT JOIN item_price_tier ipt ON ipt.`item_id`=i_item_id
	    AND ipt.`price_tier_id`=i_price_tier_id
	WHERE i.id=p_item_id;
	
	SELECT COUNT(*) INTO p_count 
	FROM sale_order 
	WHERE desk_id=i_desk_id
	AND group_id=i_group_id
	AND location_id=i_location_id
	AND `status`=p_status;
	
	IF p_count=0 THEN 
	
		INSERT INTO sale_order (sale_time,desk_id,group_id,client_id,employee_id,location_id,first_order_by)
		VALUES(p_sale_time, i_desk_id,i_group_id, i_client_id,i_employee_id,i_location_id,i_employee_id)
		ON DUPLICATE  KEY UPDATE id=LAST_INSERT_ID(id),employee_id=i_employee_id;
		
		SELECT LAST_INSERT_ID() INTO p_sale_id;
			
	ELSE 
		SELECT id INTO p_sale_id 
		FROM sale_order 
		WHERE desk_id=i_desk_id
		AND group_id=i_group_id
		AND location_id=i_location_id
		AND `status`=p_status; 
	
	END IF;
	
	UPDATE desk SET occupied=p_status WHERE id=i_desk_id;
	
	update sale_order set temp_status='2' where id=p_sale_id AND location_id=i_location_id;
	
	INSERT INTO sale_order_item(sale_id,item_id,quantity,price,item_parent_id,location_id)
	VALUES(p_sale_id,p_item_id,i_quantity,p_price,i_item_parent_id,i_location_id)
	ON DUPLICATE KEY UPDATE quantity=quantity+i_quantity,price=p_price;
	
END IF;
return p_item_id;
	
END */$$
DELIMITER ;

/* Function  structure for function  `func_change_table` */

/*!50003 DROP FUNCTION IF EXISTS `func_change_table` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_change_table`( i_desk_id INT(11),i_new_desk_id int(11), i_group_id INT(11),i_location_id INT(11),i_price_tier_id int(11),i_employee_id INT(11)) RETURNS int(11)
BEGIN
    
    DECLARE p_count smallint;
    declare p_group_id smallint;
    DECLARE p_sale_id int(11);
    declare p_employee_id int(11);
    DECLARE p_trans_time DATETIME;
    DECLARE p_status TINYINT DEFAULT 1;
    declare p_remark varchar(15) default 'CHTBL';
    
    SET p_trans_time:=NOW();
 
    SELECT id,employee_id INTO p_sale_id,p_employee_id
    FROM sale_order 
    WHERE desk_id=i_desk_id
    AND group_id=i_group_id
    AND location_id=i_location_id
    AND `status`=p_status;	
    
    -- Check if the current table there is an Item in cart
    select count(*) into p_count
    from sale_order_item
    where sale_id=p_sale_id
    and location_id=i_location_id;
    
    if p_count>0 then
     
	    -- check if the change / same table existed in Sale Ordering we have to set different group (group_id = group_id +1)
	    select count(*) into p_count 
	    from sale_order 
	    where desk_id=i_new_desk_id 
	    and group_id=i_group_id 
	    and location_id=i_location_id
	    AND `status`=p_status;
	    -- and id in (select sale_id from sale_order_item);
	    
	    if p_count>0 then
		select max(group_id)+1 into p_group_id 
		from sale_order 
		where desk_id=i_new_desk_id  -- Stupidly set old table poor me :) 
		-- AND group_id=i_group_id 
		AND location_id=i_location_id
		and `status`=p_status;    
	    else
		set p_group_id=i_group_id;
	    end if; 
	    
	    -- Update New Table to Sale Ordering
	    update sale_order 
	    set desk_id=i_new_desk_id,
		group_id=p_group_id,
		employee_id=i_employee_id
	    where desk_id=i_desk_id 
	    and group_id=i_group_id 
	    and location_id=i_location_id
	    and `status`=p_status;
	    
	    UPDATE sale_order_item t1	
	    JOIN (SELECT i.`id`,
		 CASE WHEN ipt.`price` IS NOT NULL THEN ipt.`price`
		      ELSE i.`unit_price`
		 END unit_price
		FROM `item` i LEFT JOIN item_price_tier ipt ON ipt.`item_id`=i.id
			  AND ipt.`price_tier_id`=i_price_tier_id
		) t2  ON t1.item_id=t2.id
	    SET t1.price=t2.unit_price
	    WHERE t1.sale_id=p_sale_id
	    AND t1.location_id=i_location_id;
	    
	    UPDATE desk
	    SET occupied=p_status
	    WHERE id=i_new_desk_id;
	    
	    -- Freeing up the old desk status and ensure not serving in other group
	    UPDATE desk
	    SET occupied=0
	    WHERE id=i_desk_id
	    AND id NOT IN (SELECT DISTINCT desk_id 
			   FROM sale_order 
			   WHERE desk_id=i_desk_id 
			   AND group_id<>i_group_id 
			   AND location_id=i_location_id 
			   AND `status`=p_status
			   AND id IN (SELECT sale_id FROM sale_order_item) );
			   
	   /**** For auditing purpose to be remove if encounter performance issue ***/
	   insert into sale_order_audit_log(sale_id,cur_desk_id,new_desk_id,cur_group_id,new_group_id,cur_employee_id,new_employee_id,location_id,remark,modified_date)
	   values(p_sale_id,i_desk_id,i_new_desk_id,i_group_id,p_group_id,p_employee_id,i_employee_id,i_location_id,p_remark,p_trans_time);
			 
    end if;
    
    return p_group_id;
    
    END */$$
DELIMITER ;

/* Function  structure for function  `func_clear_giftcard` */

/*!50003 DROP FUNCTION IF EXISTS `func_clear_giftcard` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_clear_giftcard`(i_sale_id INT(11),i_location_id INT(11)) RETURNS int(11)
BEGIN
DECLARE p_return_val tinyint DEFAULT 0;
DECLARE p_status TINYINT DEFAULT 1;
 UPDATE sale_order s	 
   SET giftcard_id = null , discount_amount = NULL
 WHERE s.id = i_sale_id
 AND s.location_id = i_location_id
 AND s.`status`= p_status;
	
RETURN p_return_val;
 
END */$$
DELIMITER ;

/* Function  structure for function  `func_del_order` */

/*!50003 DROP FUNCTION IF EXISTS `func_del_order` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_del_order`(i_item_id INT(11),i_item_parent_id INT(11),i_desk_id INT(11),i_group_id INT(11),i_location_id INT(11)) RETURNS int(11)
BEGIN
DECLARE p_sale_order_id INT(11);
DECLARE p_count INT(11);
DECLARE p_status TINYINT DEFAULT 1;
	
	SELECT id INTO p_sale_order_id 
	FROM sale_order 
	WHERE desk_id=i_desk_id 
	AND group_id=i_group_id 
	AND location_id=i_location_id 
	AND `status`=p_status;
		
	DELETE 
	FROM sale_order_item 
	WHERE sale_id=p_sale_order_id 
	AND location_id=i_location_id
	AND item_id=i_item_id 
	AND item_parent_id=i_item_parent_id;
	
	UPDATE sale_order SET temp_status='2' WHERE id=p_sale_order_id AND location_id=i_location_id;	
	
	SELECT COUNT(*) INTO p_count  FROM sale_order_item WHERE sale_id=p_sale_order_id AND location_id=i_location_id;
	
	IF p_count=0 THEN
  
	    /* This two statment must be execute in order, otherwise no more desk_id found */
  
	    UPDATE desk
	    SET occupied=0
	    WHERE id=i_desk_id
	    AND id NOT IN (SELECT DISTINCT desk_id 
			   FROM sale_order 
			   WHERE desk_id=i_desk_id 
			   AND group_id<>i_group_id 
			   AND location_id=i_location_id 
			   AND `status`=p_status	
			   );
			   
	    DELETE FROM sale_order WHERE id=p_sale_order_id AND `status`=p_status;
				
	END IF;
	
	
return i_item_id;
 
END */$$
DELIMITER ;

/* Function  structure for function  `func_edit_order` */

/*!50003 DROP FUNCTION IF EXISTS `func_edit_order` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_edit_order`(i_sale_id INT,i_item_id INT,i_quantity DOUBLE(15,2),i_price DOUBLE(15,2),i_discount DOUBLE(15,2), i_item_parent_id INT(11),i_location_id INT(11)) RETURNS int(11)
BEGIN
DECLARE p_status TINYINT DEFAULT 1;
   
UPDATE sale_order_item
SET quantity=i_quantity
WHERE sale_id=i_sale_id
AND location_id=i_location_id
AND item_id=i_item_id
AND item_parent_id= i_item_parent_id;
return i_item_id;
	
END */$$
DELIMITER ;

/* Function  structure for function  `func_save_pkitchen` */

/*!50003 DROP FUNCTION IF EXISTS `func_save_pkitchen` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`sys`@`%` FUNCTION `func_save_pkitchen`(i_sale_id INT(11),i_location_id INT(11),i_category_id INT(11),i_employee_id INT(11)) RETURNS int(11)
BEGIN
    
	-- DECLARE p_sale_id INT(11) default 0;
	DECLARE p_status TINYINT DEFAULT 1;
	declare p_count TINYINT DEFAULT 0;
	    
	-- no longer use since we can always get sale_id when focusing on that table	
	/* SELECT id INTO p_sale_id FROM sale_order WHERE desk_id=i_desk_id AND group_id=i_group_id AND location_id=i_location_id AND `status`=p_status; */
	
	UPDATE sale_order
	SET employee_id=i_employee_id
	WHERE id=i_sale_id
	AND location_id=i_location_id
	AND `status`=p_status;
	
	INSERT INTO sale_order_item_print(`sale_id`,`item_id`,`description`,`line`,`quantity`,`cost_price`,`unit_price`,`price`,`discount_amount`,`discount_type`,`modified_date`,`item_parent_id`,`path`,location_id)
	SELECT `sale_id`,`item_id`,t1.`description`,t1.`line`,t1.`quantity`,t1.`cost_price`,t1.`unit_price`,t1.`price`,t1.`discount_amount`,t1.`discount_type`,t1.`modified_date`,t1.`item_parent_id`,t1.`path`,t1.location_id
	FROM sale_order_item t1 , item t2
	WHERE sale_id=i_sale_id
	AND location_id=i_location_id
	AND t1.item_id=t2.id
	AND t2.category_id=i_category_id
	ON DUPLICATE KEY UPDATE quantity=t1.quantity;
	
	SELECT count(*) into p_count
	FROM v_order_cart t1 LEFT JOIN
		(SELECT t2.sale_id,t2.item_id,t2.item_parent_id ,t2.quantity
		 FROM sale_order_item_print t2 , item t3
		 WHERE t3.id=t2.item_id
		 AND t3.category_id<>i_category_id
		) t2
	    ON t2.sale_id=t1.`sale_id`
	    AND t2.item_id=t1.item_id
	    AND t2.item_parent_id=t1.item_parent_id
	WHERE t1.sale_id=i_sale_id and t1.location_id=i_location_id
	AND t1.status=p_status
	AND (t1.quantity-IFNULL(t2.quantity,0))>0
	AND t1.category_id<>i_category_id;
	
	if p_count=0 then 
	    update sale_order 
	    set temp_status='0'
	    WHERE id=i_sale_id
	    AND location_id=i_location_id
	    AND `status`=p_status;
	end if;
	
	return i_sale_id;
	
    END */$$
DELIMITER ;

/* Function  structure for function  `func_save_sale` */

/*!50003 DROP FUNCTION IF EXISTS `func_save_sale` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_save_sale`(i_desk_id int(11), i_group_id int(11),i_location_id INT(11),i_payment_total double,i_employee_id INT(11)) RETURNS int(11)
BEGIN
	
	declare p_sale_order_id int(11) default -1;
	declare p_sale_id int(11);
	DECLARE p_status TINYINT DEFAULT 1;
	DECLARE p_zero_status TINYINT DEFAULT 0;
	DECLARE p_trans_time DATETIME;
	declare p_count tinyint default 0;
	
	SET p_trans_time:=NOW();
	
	
	-- Check if there is an active ordering in cart
	select count(*) into p_count 
	from sale_order
	WHERE desk_id=i_desk_id 
	AND group_id=i_group_id 
	AND location_id=i_location_id 
	AND `status`=p_status;
	
	if p_count>0 then
		
		select id into p_sale_order_id 
		from sale_order 
		where desk_id=i_desk_id 
		and group_id=i_group_id 
		AND location_id=i_location_id 
		and `status`=p_status;
		
		-- Updating [sub_total] column
		UPDATE sale_order so
		INNER JOIN (SELECT sale_id,location_id,SUM(price*quantity) sub_total
			    FROM sale_order_item
			    WHERE sale_id=p_sale_order_id
			    AND location_id=i_location_id
			    GROUP BY sale_id,location_id
			   ) soi ON soi.sale_id=so.id AND soi.`location_id`=so.`location_id`
		SET so.sub_total=soi.sub_total
		WHERE so.id=p_sale_order_id;
		
		-- Saving the employee who saving the sale i_employee_id - sometime the ordering employee is different
		INSERT INTO sale(id,sale_time,client_id,desk_id,zone_id,group_id,employee_id,location_id,sub_total,payment_type,STATUS,remark,discount_amount,discount_type,first_order_by)
		SELECT id,sale_time,client_id,desk_id,zone_id,group_id,i_employee_id,location_id,sub_total,payment_type,STATUS,remark,discount_amount,discount_type,first_order_by
		FROM sale_order
		WHERE id=p_sale_order_id
		and location_id=i_location_id
		and `status`=p_status;
		
		INSERT INTO sale_item(sale_id,item_id,description,line,quantity,cost_price,unit_price,price,discount_amount,discount_type,item_parent_id,path,location_id)
		SELECT sale_id,item_id,description,line,quantity,cost_price,unit_price,price,discount_amount,discount_type,item_parent_id,path,location_id
		FROM sale_order_item
		WHERE sale_id=p_sale_order_id
		and location_id=i_location_id; 
		
		-- Inserting payment to sale_payment table
		insert into sale_payment(`sale_id`,`payment_type`,`payment_amount`,`date_paid`,`modified_date`)
		select p_sale_order_id,'Cash' payment_type,i_payment_total,p_trans_time,p_trans_time;
		
		 -- Freeing up table to available by updating [occupied] = 0 
		 UPDATE desk
		 SET occupied=p_zero_status
		 WHERE id=i_desk_id
		 AND id NOT IN (SELECT DISTINCT desk_id 
			   FROM sale_order 
			   WHERE desk_id=i_desk_id 
			   AND group_id<>i_group_id 
			   AND location_id=i_location_id 
			   AND `status`=p_status);
			   -- AND id IN (SELECT sale_id FROM sale_order_item) ); -- Not neccesary as long as Sale_Order Registering
			   
		-- Updating sale_order status to zero - completed
		UPDATE sale_order 
		SET `status`=p_zero_status,
		     employee_id=i_employee_id
		WHERE id=p_sale_order_id
		AND location_id=i_location_id
		AND `status`=p_status;	 
	
	end if;  
		
	return p_sale_order_id;
    
 END */$$
DELIMITER ;

/* Function  structure for function  `func_set_giftcard` */

/*!50003 DROP FUNCTION IF EXISTS `func_set_giftcard` */;
DELIMITER $$

/*!50003 CREATE  FUNCTION `func_set_giftcard`(i_sale_id int(11),i_location_id INT(11),i_giftcard_id varchar(25)) RETURNS int(11)
BEGIN
DECLARE p_return_val tinyint default 0;
DECLARE p_count TINYINT default 0;
DECLARE p_status TINYINT DEFAULT 1;
declare p_giftcard_id int(11) default 0;
declare p_discount_amount decimal(15,2);
select count(*) into p_count from `giftcard` where giftcard_number = i_giftcard_id;
if p_count > 0 then 
 select id into p_giftcard_id from giftcard where giftcard_number=i_giftcard_id;
else
 SELECT id INTO p_giftcard_id FROM giftcard WHERE id=i_giftcard_id;
end if;
if p_giftcard_id > 0 then
  
 select id,discount_amount into p_giftcard_id,p_discount_amount 
 from giftcard
 where id=p_giftcard_id;
 
 update sale_order s	 
   set giftcard_id = p_giftcard_id , discount_amount = p_discount_amount
 where s.id = i_sale_id
 and s.location_id = i_location_id
 and s.`status`= p_status;
 
 set p_return_val=1;
 
end if;
		
RETURN p_count;
 
END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_add_order_item` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_add_order_item` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_add_order_item`(i_item_id INT(11),i_item_number VARCHAR(10),i_desk_id INT(11),i_group_id INT(11),i_client_id INT(11),i_employee_id INT(11),i_quantity DOUBLE(15,2),i_price_tier_id INT(11),i_item_parent_id INT(11),i_location_id INT(11))
BEGIN
DECLARE p_sale_id INT(11);
DECLARE p_price DOUBLE(15,4);
DECLARE p_sale_time DATETIME;
DECLARE p_count SMALLINT;
DECLARE p_item_id INT(11);
declare p_status tinyint default 1;
   
START TRANSACTION;   
SELECT 'hi';
SET p_sale_time:=DATE_ADD(NOW(), INTERVAL 0 HOUR);
SET p_item_id=i_item_id;
SELECT COUNT(*) INTO p_count FROM item WHERE item_number=i_item_number;
IF p_count>0 THEN
   SELECT id INTO p_item_id FROM item WHERE item_number=i_item_number;
END IF;
if p_item_id >0 then  
            
	SELECT 
	    CASE WHEN ipt.`price` IS NOT NULL THEN ipt.`price`
		ELSE i.`unit_price`
	    END INTO p_price
	FROM `item` i LEFT JOIN item_price_tier ipt ON ipt.`item_id`=i_item_id
	    AND ipt.`price_tier_id`=i_price_tier_id
	WHERE i.id=p_item_id;
	
	SELECT COUNT(*) INTO p_count 
	FROM sale_order 
	WHERE desk_id=i_desk_id
	AND group_id=i_group_id
	AND location_id=i_location_id
	AND `status`=p_status;
	
	IF p_count=0 THEN 
	
		INSERT INTO sale_order (sale_time,desk_id,group_id,client_id,employee_id,location_id,first_order_by)
		VALUES(p_sale_time, i_desk_id,i_group_id, i_client_id,i_employee_id,i_location_id,i_employee_id)
		ON DUPLICATE  KEY UPDATE id=LAST_INSERT_ID(id),employee_id=i_employee_id;
		
		SELECT LAST_INSERT_ID() INTO p_sale_id;
			
	ELSE 
		SELECT id INTO p_sale_id 
		FROM sale_order 
		WHERE desk_id=i_desk_id
		AND group_id=i_group_id
		AND location_id=i_location_id
		AND `status`=p_status; 
	
	END IF;
	
	/** No more need this, added default CURRENT_TIMESTAMP on created out of the box mysql function 
	**/
	/*
	SELECT COUNT(*) INTO p_count 
	FROM sale_order_item 
	WHERE sale_id=p_sale_id
	AND location_id=i_location_id;
	
	if p_count=0 then
	     -- To only update the sale time when all item in cart / [sale_order] been erased OR 1st time insert only
	      UPDATE sale_order
	      SET sale_time = p_sale_time
	      WHERE id=p_sale_id
	      AND location_id=i_location_id;
	end if;
	*/
	
	
	/**
	  Consider obsolete block since empty_flag no more use, employee_id does not always neccesary always update here
	**/
	-- Always update the sale_time and employee_id to the latest execute transaction - consider to create another column modified date instead
	/*	
	update sale_order 
	set empty_flag=1,
	    -- sale_time=p_sale_time,
	    employee_id=i_employee_id
	where id=p_sale_id
	and location_id=i_location_id;
	*/
	
	update desk set occupied=p_status where id=i_desk_id;
	
	INSERT INTO sale_order_item(sale_id,item_id,quantity,price,modified_date,item_parent_id,location_id)
	VALUES(p_sale_id,p_item_id,i_quantity,p_price,p_sale_time,i_item_parent_id,i_location_id)
	ON DUPLICATE KEY UPDATE quantity=quantity+i_quantity,price=p_price;
	
	COMMIT;
	
end if;
	
END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_add_order_item_old` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_add_order_item_old` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_add_order_item_old`(i_item_id varchar(50),i_desk_id int(11),i_group_id INT(11),i_client_id INT(11),i_employee_id INT(11),i_quantity double(15,2),i_price_tier_id int(11),i_item_parent_id int(11),i_location_id INT(11))
BEGIN
DECLARE p_sale_id INT(11);
declare p_price double(15,4);
declare p_sale_time datetime;
declare p_count smallint;
declare p_item_id int(11);
   
START TRANSACTION;   
SELECT 'hi';
set p_sale_time:=now();
set p_item_id=i_item_id;
select count(*) into p_count from item where id=i_item_id;
if p_count=0 then
select id into p_item_id from item where item_number=i_item_id;
end if;
            
SELECT 
    CASE WHEN ipt.`price` IS NOT NULL THEN ipt.`price`
	ELSE i.`unit_price`
    END into p_price
FROM `item` i LEFT JOIN item_price_tier ipt ON ipt.`item_id`=i_item_id
    AND ipt.`price_tier_id`=i_price_tier_id
WHERE i.id=p_item_id;
select count(*) into p_count 
from sale_order 
where desk_id=i_desk_id
and group_id=i_group_id
and location_id=i_location_id
and `status`=1;
if p_count=0 then 
	INSERT INTO sale_order (sale_time,desk_id,group_id,client_id,employee_id,location_id)
	VALUES(p_sale_time, i_desk_id,i_group_id, i_client_id,i_employee_id,i_location_id)
	ON DUPLICATE  KEY UPDATE id=LAST_INSERT_ID(id),employee_id=i_employee_id;
	select LAST_INSERT_ID() into p_sale_id;
else 
	select id into p_sale_id 
	FROM sale_order 
	WHERE desk_id=i_desk_id
	AND group_id=i_group_id
	AND location_id=i_location_id
	AND `status`=1; 
end if;
INSERT INTO sale_order_item(sale_id,item_id,quantity,price,modified_date,item_parent_id,location_id)
VALUES(p_sale_id,p_item_id,i_quantity,p_price,now(),i_item_parent_id,i_location_id)
ON DUPLICATE KEY UPDATE quantity=quantity+i_quantity,price=p_price;
COMMIT;
	
END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_del_item_cart` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_del_item_cart` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_del_item_cart`(i_item_id int(11),i_item_parent_id int(11),i_desk_id int(11),i_group_id int(11),i_location_id INT(11))
BEGIN
	DECLARE p_sale_order_id INT(11);
	declare p_count int(11);
	declare p_status tinyint default 1;
	
	START TRANSACTION; 
	SELECT 'hi';	
	
	SELECT id INTO p_sale_order_id FROM sale_order 
	WHERE desk_id=i_desk_id 
	AND group_id=i_group_id 
	AND location_id=i_location_id 
	AND `status`=p_status;
	
	delete 
	from sale_order_item 
	where sale_id=p_sale_order_id 
	and location_id=i_location_id
	AND item_id=i_item_id 
	AND item_parent_id=i_item_parent_id;
	
	select count(*) into p_count 
	from sale_order_item 
	WHERE sale_id=p_sale_order_id
	and location_id=i_location_id;
	
	if p_count=0 then
	  
	   DELETE FROM sale_order WHERE id=p_sale_order_id AND `status`=p_status;		
	  
	    -- Freeing up desk status
	    update desk
	    set occupied=0
	    where id=i_desk_id
	    and id not in (select distinct desk_id 
			   from sale_order 
			   WHERE desk_id=i_desk_id 
			   and group_id<>i_group_id 
			   and location_id=i_location_id 
			   and `status`=p_status);
			   -- and id IN (SELECT sale_id FROM sale_order_item));
			   
	    -- delete from sale_order where id=p_sale_order_id and `status`=p_status;
	
	end if;
	
	commit;
	
    END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_del_sale_order` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_del_sale_order` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_del_sale_order`(i_desk_id int(11),i_group_id int(11),i_location_id INT(11))
BEGIN
	DECLARE p_sale_order_id INT(11);
	
	SELECT 'hi';	
	
	SELECT id INTO p_sale_order_id 
	FROM sale_order 
	WHERE desk_id=i_desk_id 
	AND group_id=i_group_id 
	AND location_id=i_location_id
	and `status`=1;
	
	-- MYISAM enginne recycle / reuse ID after deleted
	-- delete from sale_order_item where sale_id=p_sale_order_id AND location_id=i_location_id;
	
	update sale_order 
	set `status`=0
	where id=p_sale_order_id
	AND location_id=i_location_id
	AND `status`=1;
	
	commit;
	
    END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_edit_menu_order` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_edit_menu_order` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_edit_menu_order`(i_desk_id int, i_group_id INT,i_item_id INT,i_quantity double(15,2),i_price double(15,2),i_discount double(15,2), i_item_parent_id int(11),i_location_id INT(11))
BEGIN
DECLARE p_sale_id int(11);
DECLARE p_status TINYINT DEFAULT 1;
   
START TRANSACTION;   
SELECT 'hi';
       
	select id into p_sale_id 
	from sale_order 
	where desk_id=i_desk_id 
	and group_id=i_group_id 
	AND location_id=i_location_id 
	AND `status`=p_status;
	update sale_order_item
	set quantity=i_quantity
	where sale_id=p_sale_id
	and location_id=i_location_id
	and item_id=i_item_id
	and item_parent_id= i_item_parent_id;
	
COMMIT;
	
END */$$
DELIMITER ;

/* Procedure structure for procedure `proc_remove_order_item` */

/*!50003 DROP PROCEDURE IF EXISTS  `proc_remove_order_item` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `proc_remove_order_item`(i_item_id int(11),i_item_parent_id int(11),i_desk_id int(11),i_group_id int(11),i_location_id INT(11))
BEGIN
	DECLARE p_sale_order_id INT(11);
	declare p_count int(11);
	declare p_status tinyint default 1;
	
	START TRANSACTION; 
	SELECT 'hi';	
	
	SELECT id INTO p_sale_order_id 
	FROM sale_order 
	WHERE desk_id=i_desk_id 
	AND group_id=i_group_id 
	AND location_id=i_location_id 
	AND `status`=p_status;
	
	delete 
	from sale_order_item 
	where sale_id=p_sale_order_id 
	and location_id=i_location_id
	AND item_id=i_item_id 
	AND item_parent_id=i_item_parent_id;
	
	select count(*) into p_count 
	from sale_order_item 
	WHERE sale_id=p_sale_order_id
	and location_id=i_location_id;
	
	if p_count=0 then
	  
	    DELETE FROM sale_order WHERE id=p_sale_order_id AND `status`=p_status;	
	  
	    update desk
	    set occupied=0
	    where id=i_desk_id
	    and id not in (select distinct desk_id 
			   from sale_order 
			   WHERE desk_id=i_desk_id 
			   and group_id<>i_group_id 
			   and location_id=i_location_id 
			   and `status`=p_status	
			   );
			   	
	    /**
	       Obsolete block consider using on delete casecade of mysql feature
	    **/
	    -- Freeing up desk status 
	    /*
	    update desk
	    set occupied=0
	    where id=i_desk_id
	    and id not in (select distinct desk_id 
			   from sale_order 
			   WHERE desk_id=i_desk_id 
			   and group_id<>i_group_id 
			   and location_id=i_location_id 
			   and `status`=p_status
			   and id IN (SELECT sale_id FROM sale_order_item));
			   
	    delete from sale_order where id=p_sale_order_id and `status`=p_status;
	    */
	
	end if;
	
	commit;
	
    END */$$
DELIMITER ;

/* Procedure structure for procedure `pro_save_pkitchen` */

/*!50003 DROP PROCEDURE IF EXISTS  `pro_save_pkitchen` */;

DELIMITER $$

/*!50003 CREATE  PROCEDURE `pro_save_pkitchen`(i_desk_id INT(11),i_group_id INT(11),i_location_id INT(11),i_category_id int(11),i_employee_id INT(11))
BEGIN
    
	DECLARE p_sale_id INT;
	DECLARE p_status TINYINT DEFAULT 1;
	
	select 'hi';
    
	SELECT id INTO p_sale_id FROM sale_order WHERE desk_id=i_desk_id AND group_id=i_group_id AND location_id=i_location_id AND `status`=p_status;
	
	update sale_order
	set employee_id=i_employee_id
	where id=p_sale_id
	and location_id=i_location_id
	AND `status`=p_status;
	
	INSERT INTO sale_order_item_print(`sale_id`,`item_id`,`description`,`line`,`quantity`,`cost_price`,`unit_price`,`price`,`discount_amount`,`discount_type`,`modified_date`,`item_parent_id`,`path`,location_id)
	SELECT `sale_id`,`item_id`,t1.`description`,t1.`line`,t1.`quantity`,t1.`cost_price`,t1.`unit_price`,t1.`price`,t1.`discount_amount`,t1.`discount_type`,t1.`modified_date`,t1.`item_parent_id`,t1.`path`,t1.location_id
	FROM sale_order_item t1 , item t2
	WHERE sale_id=p_sale_id
	and location_id=i_location_id
	and t1.item_id=t2.id
	and t2.category_id=i_category_id
	ON DUPLICATE KEY UPDATE quantity=t1.quantity;
	
    END */$$
DELIMITER ;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
