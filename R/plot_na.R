#' @importFrom ggplot2 scale_color_discrete

plot_na_single <- function(df_plot, df_names, text_labels, col_palette){
  # convert col_name to factor
  
  dfpcnt = c(-0.05, max(df_plot$pcnt, na.rm = T) + abs(diff(range(df_plot$pcnt, na.rm = T)))/100)
  
  df_plot <- df_plot %>% 
    mutate(col_name = factor(col_name, levels = as.character(col_name)))
  # construct bar plot of missingess
  plt <- bar_plot(df_plot = df_plot, x = "col_name", y = "pcnt", 
                  fill = "col_name", label = "cnt",
                  ttl = paste0("Prevalence of NAs in df::", df_names$df1),
                  sttl = paste0("df::", df_names$df1,  " has ", nrow(df_plot), 
                                " columns, of which ", sum(df_plot$cnt > 0), 
                                " have missing values"),
                  ylb = "% of column that is NA", 
                  rotate = TRUE, 
                  col_palette = col_palette,
                  ylim_range = NULL)
  # add text annotation to plot if requested
  if(text_labels){
    plt <- add_annotation_to_bars(x = df_plot$col_name, 
                                  y = df_plot$pcnt, 
                                  z = df_plot$cnt, 
                                  plt = plt)
  }
  plt
}

plot_na_pair <- function(df_plot, df_names, alpha, text_labels, col_palette){
  leg_text <- as.character(unlist(df_names))
  na_tab  <- df_plot
  df_plot <- df_plot %>% 
    select(-starts_with("cnt")) %>% 
    gather(key = "data_frame", value = "pcnt", -col_name, -p_value) %>%
    mutate(data_frame = gsub("pcnt_", "", data_frame))
  df_plot <- df_plot[seq(dim(df_plot)[1],1),]
  p_val_tab <- df_plot %>% 
    mutate(is_sig = as.integer(p_value < alpha) + 2, index = 1:nrow(df_plot)) %>%
    replace_na(list(is_sig = 1)) %>%
    select(is_sig, index) 
  plt <- ggplot(df_plot, aes(x = factor(col_name, levels = rev(as.character(na_tab$col_name))), 
                                 y = pcnt, color = as.factor(data_frame))) +
    geom_blank() + theme_bw() + 
    theme(panel.border = element_blank(), panel.grid.major = element_blank()) +
    geom_rect(
      fill = c(NA, "gray50", user_colours(9, col_palette)[9])[p_val_tab$is_sig], alpha = 0.2,
      xmin = p_val_tab$index - 0.4, xmax = p_val_tab$index + 0.4,
      ymin = -100, ymax = 200, linetype = "blank") +
    geom_hline(yintercept = 0, linetype = "dashed", color = "lightsteelblue4") + 
    geom_point(size = 1.25 * dot_size(nrow(df_plot)), color = "black", na.rm = TRUE) + 
    geom_point(size = dot_size(nrow(df_plot)), na.rm = TRUE) +
    scale_colour_manual(values = get_best_pair(col_palette), 
                        name = "Data frame", labels = leg_text) + 
    coord_flip() + 
    labs(x = "", 
         title =  paste0("% NA in df::", df_names$df1, " and df::", df_names$df2),
         subtitle = bquote("Color/gray stripes mean different/equal missingness")) + 
    labs(y = "% of column that is NA", x = "") +
    guides(color = guide_legend(override.aes = list(fill = NA)))
  
  plt
}

plot_na_grouped <- function(df_plot, df_names, text_labels, col_palette, plot_type){
  # group variable name
  group_name <- colnames(df_plot)[1]
  if(plot_type == 1){
    # get ordering of variable pairs by median correlation
    col_ord <- df_plot %>% 
      ungroup %>%
      group_by(col_name) %>%
      summarize(md_pcnt = median(pcnt, na.rm = T)) %>%
      arrange(md_pcnt) %>%
      .$col_name
    # create pair columns and arrange by col_ord
    out <- df_plot %>% 
      ungroup %>%
      mutate(col_name = factor(col_name, levels = col_ord)) %>%
      arrange(col_name) 
    # jitter points if number of column pairs <= 10
    jitter_width <- ifelse(length(unique(out$col_name)) > 10, 0, 0.25) 
    plt <- out %>%
      ggplot(aes_string(x = 'col_name', y = 'pcnt', col = 'col_name', group = group_name)) + 
      geom_jitter(alpha = 0.5, width = jitter_width, height = 0, size = 1.8) + 
      theme(legend.position='none') + 
      coord_flip() + 
      ylab("Missingness by group") +
      xlab("")
  } else {
    plt <- plot_grouped(df = df_plot, 
                        value = "pcnt", 
                        series = "col_name", 
                        group = group_name, 
                        plot_type = plot_type, 
                        col_palette = col_palette, 
                        text_labels = text_labels, 
                        ylab = "% missing")
  } 
  plt
}


