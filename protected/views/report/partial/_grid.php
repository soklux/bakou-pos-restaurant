<div class="table-header">
    <?= Yii::t('app',$title) . ' ' .  Yii::t('app','From') . ' ' . $from_date . '  ' . Yii::t('app','To') . ' ' . $to_date; ?>
</div>

<?php $this->widget('EExcelView', array(
    'id' => $grid_id,
    'fixedHeader' => true,
    'type' => TbHtml::GRID_TYPE_BORDERED,
    'dataProvider' => $data_provider,
    'template' => "{items}\n{exportbuttons}\n",
    'columns' => $grid_columns,
));
