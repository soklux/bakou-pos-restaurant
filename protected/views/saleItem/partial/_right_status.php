<?php if (isset($table_info)) { ?>
    <span class="label label-info label-xlg">
        <?php echo '<b>' .  $table_info->name  .' - ' . Common::GroupAlias(Yii::app()->orderingCart->getGroupId()) . '</b>'; ?>
        <i class="ace-icon fa fa-clock-o"></i>
        <?= $time_go; ?>
    </span>
<?php } ?>
<?php if (isset($ordering_status)) { ?>
    <span class="order-status <?php echo $ordering_status_span; ?>">
        <i class="<?php echo $ordering_status_icon; ?>"></i>
        <?= $ordering_msg; ?>
    </span>
<?php } ?>
