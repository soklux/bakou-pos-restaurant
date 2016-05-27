<div id="report_header">
    <?php $form=$this->beginWidget('bootstrap.widgets.TbActiveForm',array(
        'id'=>'report-form',
        'method'=>'get',
        'action' => Yii::app()->createUrl($this->route),
        'enableAjaxValidation'=>false,
        'layout'=>TbHtml::FORM_LAYOUT_INLINE,
    )); ?>

        <label class="text-info" for="from_date"><?php echo Yii::t('app','Start Date'); ?></label>
        <div class="input-group">
            <?php $this->widget('yiiwheels.widgets.datepicker.WhDatePicker', array(
                'attribute' => 'from_date',
                'model' => $report,
                'pluginOptions' => array(
                    'format' => 'dd-mm-yyyy',
                )
            ));
            ?>
            <span class="input-group-addon"><i class="ace-icon fa fa-calendar"></i></span>
        </div>

        <label class="text-info" for="to_date"><?php echo Yii::t('app','End Date'); ?></label>
        <div class="input-group">
            <?php $this->widget('yiiwheels.widgets.datepicker.WhDatePicker', array(
                'attribute' => 'to_date',
                'model' => $report,
                'pluginOptions' => array(
                    'format' => 'dd-mm-yyyy'
                )
            ));
            ?>
            <span class="input-group-addon"><i class="ace-icon fa fa-calendar"></i></span>
        </div>

        <button class="btn btn-white btn-info btn-bold btn-view">
            <i class="ace-icon fa fa-eye bigger-120 blue"></i>
            <?= Yii::t('app','View'); ?>
        </button>

    <?php $this->endWidget(); ?>

</div>

<script>
    jQuery( function($){
        $('div#report_header').on('click','.btn-view',function(e) {
            e.preventDefault();
            var data=$("#report-form").serialize();
            $.ajax({url: '<?=  Yii::app()->createUrl($this->route); ?>',
                type : 'GET',
                dataType : 'json',
                data:data,
                beforeSend: function() { $('.waiting').show(); },
                complete: function() { $('.waiting').hide(); },
                success : function(data) {
                    $("#report_grid").html(data.div);
                    return false;
                }
            });
        });
    });
</script>


